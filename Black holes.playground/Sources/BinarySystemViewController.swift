import UIKit
import SpriteKit
import AVFoundation
import AudioUnit

let scale: CGFloat = 150 // px per meter

public struct BinarySystem {
    
    public var firstMass: Float = 3
    public var secondMass: Float = 1.5
    public var initialAngle: Float = 0
    
    var totalMass: Float { return firstMass + secondMass }
    
    var chirpMass: Float {
        return pow(firstMass * secondMass, 3 / 5) / pow(totalMass, 1 / 5)
    }
    
    func radiationFrequency(_ t: Float) -> Float {
        return pow(chirpMass, -5 / 8) * pow(t, -3 / 8)
    }
    func distance(_ t: Float) -> Float {
        return pow(chirpMass / 4, 1 / 3) * pow(.pi * radiationFrequency(t), -2 / 3)
    }
    func rotationAngle(_ t: Float) -> Float {
        return .pi * pow(radiationFrequency(t) * chirpMass, -5 / 3) - initialAngle
    }
    func radialUnitVector(_ t: Float) -> vector_float3 {
        let phi = rotationAngle(t)
        return vector_float3(cos(phi), sin(phi), 0)
    }
    func firstRadius(_ t: Float) -> Float {
        return secondMass / totalMass * distance(t)
    }
    func firstBlackhole(_ t: Float) -> BlackHole {
        return BlackHole(mass: firstMass, position: firstRadius(t) * radialUnitVector(t))
    }
    func secondRadius(_ t: Float) -> Float {
        return firstMass / totalMass * distance(t)
    }
    func secondBlackhole(_ t: Float) -> BlackHole {
        return BlackHole(mass: secondMass, position: -secondRadius(t) * radialUnitVector(t))
    }
    
    var finalRadiatedEnergy: Float {
        return 0 // TODO
    }
    var finalBlackhole: BlackHole {
        return BlackHole(mass: totalMass - finalRadiatedEnergy, position: vector_float3(0, 0, 0))
    }
}



public class BinarySystemScene: SKScene {
    
    var binarySystem: BinarySystem = BinarySystem()
    
    var coalescenceTime: Date?
    /// Real-time duration of simulation until coalescence
    var duration: TimeInterval = 20
    /// Timescale of the simulation. Simulates more physical time for a small timescale, thus moving faster at constant simulation duration.
    var timescale: TimeInterval = 0.05
    var initialTime: Float {
        return Float(duration / timescale)
    }
    
    var firstBlackholeNode: CelestialBodyNode!
    var secondBlackholeNode: CelestialBodyNode!
    var finalBlackholeNode: CelestialBodyNode!
    
    let audioFrequencyPlayer = AudioFrequencyPlayer()
    let audioFrequencyUpdateRate: TimeInterval = 1 / 0.1
    
    private var backgroundTexture = SKTexture(imageNamed: "milkyway.jpg")
    private var backgroundImage: SKSpriteNode!
    
    override public init(size: CGSize) {
        super.init(size: size)
        
        self.backgroundImage = SKSpriteNode(texture: backgroundTexture)
        self.addChild(backgroundImage)
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.physicsWorld.gravity = .zero
        
        self.firstBlackholeNode = CelestialBodyNode(blackhole: binarySystem.firstBlackhole(initialTime))
        firstBlackholeNode.emitterTargetNode = self
        self.secondBlackholeNode = CelestialBodyNode(blackhole: binarySystem.secondBlackhole(initialTime))
        secondBlackholeNode.emitterTargetNode = self
        self.addChild(firstBlackholeNode)
        self.addChild(secondBlackholeNode)
        
        self.finalBlackholeNode = CelestialBodyNode(blackhole: binarySystem.finalBlackhole)
        finalBlackholeNode.emitterTargetNode = self
        
        updateMasses()
        updatePositions(initialTime)
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func startSimulation() {
        self.coalescenceTime = Date().addingTimeInterval(duration)
    }
    
    public func stopSimulation() {
        audioFrequencyPlayer.stop()
        self.coalescenceTime = nil
        finalBlackholeNode.removeFromParent()
        if case .none = firstBlackholeNode.parent {
            self.addChild(firstBlackholeNode)
        }
        if case .none = secondBlackholeNode.parent {
            self.addChild(secondBlackholeNode)
        }
    }
    
    
    private var audioFrequencyUpdate: TimeInterval?
    
    override public func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        guard let coalescenceTime = self.coalescenceTime else {
            updatePositions(initialTime)
            return
        }
        let t = Float(coalescenceTime.timeIntervalSinceNow / timescale)
        guard t > 0 else {
            if case .none = finalBlackholeNode.parent {
                let mergeDuration = 0.1
                let mergeAction = SKAction.sequence([
                    .move(to: .zero, duration: mergeDuration),
                    .removeFromParent()
                    ])
                firstBlackholeNode.run(mergeAction)
                secondBlackholeNode.run(mergeAction)
                self.addChild(finalBlackholeNode)
                finalBlackholeNode.setScale(0)
                let appearFromMergeAction = SKAction.sequence([
                    .scale(to: 1, duration: mergeDuration),
                    ])
                finalBlackholeNode.run(appearFromMergeAction)
                finalBlackholeNode.emitMergeEffect()
                audioFrequencyPlayer.stop()
            }
            return
        }
        updatePositions(t)
        
        if audioFrequencyUpdate == nil || audioFrequencyUpdate! < currentTime - 1 / audioFrequencyUpdateRate {
            let audioFrequency = binarySystem.radiationFrequency(t) / 0.07 * 200
            audioFrequencyPlayer.play(frequency: audioFrequency)
            audioFrequencyUpdate = currentTime
        }
    }
    
    func updatePositions(_ t: Float) {
        let initialRadiusNormalization = 1 / max(binarySystem.firstRadius(initialTime), binarySystem.secondRadius(initialTime))
        let x_1 = binarySystem.firstBlackhole(t).position * initialRadiusNormalization
        let x_2 = binarySystem.secondBlackhole(t).position * initialRadiusNormalization
        let viewOrbitRadius = min(self.size.width, self.size.height) / 3
        firstBlackholeNode.position = CGPoint(x: CGFloat(x_1.x) * viewOrbitRadius, y: CGFloat(x_1.y) * viewOrbitRadius)
        secondBlackholeNode.position = CGPoint(x: CGFloat(x_2.x) * viewOrbitRadius, y: CGFloat(x_2.y) * viewOrbitRadius)
    }
    
    private func updateMasses() {
        func setMass(_ mass: Float, for node: SKShapeNode) {
            let radius = 10 * CGFloat(mass)
            node.path = UIBezierPath(arcCenter: .zero, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true).cgPath
            (node.childNode(withName: "auraEffectEmitter") as? SKEmitterNode)?.particlePositionRange = CGVector(dx: 2 * radius, dy: 2 * radius)
        }
        setMass(binarySystem.firstMass, for: firstBlackholeNode)
        setMass(binarySystem.secondMass, for: secondBlackholeNode)
        setMass(binarySystem.finalBlackhole.mass, for: finalBlackholeNode)
    }
    
    
    // MARK: User Interaction
    
    private var activeTouch: UITouch?
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopSimulation()
        activeTouch = touches.first
        touchesMoved(touches, with: event)
    }
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeTouch = self.activeTouch, touches.contains(activeTouch) else { return }
        let location = activeTouch.location(in: self)
        let massRatio = Float((location.x + size.width / 2) / size.width)
        let massMagnitude = 1 + 3 * Float((location.y + size.height / 2) / size.height)
        binarySystem.firstMass = 2 * massRatio * massMagnitude
        binarySystem.secondMass = 2 * (1 - massRatio) * massMagnitude
        updateMasses()
        binarySystem.initialAngle = 0
        binarySystem.initialAngle = binarySystem.rotationAngle(initialTime)
    }
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        startSimulation()
    }
    
    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if let backgroundImage = self.backgroundImage {
            let backgroundSize = backgroundTexture.size()
            let backgroundScale = max(self.size.width / backgroundSize.width, self.size.height / backgroundSize.height)
            backgroundImage.setScale(backgroundScale)
        }
    }
    
}

public class BinarySystemViewController: UIViewController {
    
    private let simulationView = SKView(frame: .zero)
    private let simulationScene = BinarySystemScene(size: .zero)
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(simulationView)
        simulationView.presentScene(simulationScene)
        simulationScene.startSimulation()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        simulationView.frame = view.bounds
        simulationScene.size = simulationView.frame.size
    }
    
}
