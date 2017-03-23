import UIKit
import SpriteKit

private let schwarzschildCategory: UInt32 = 0x1 << 1
private let newtonCategory: UInt32 = 0x1 << 2

public struct SchwarzschildGeodesic: Geodesic {
    public let particle: Particle
    public let source: BlackHole
    public let fieldBitMask: UInt32 = schwarzschildCategory
    
    public var initialVelocity: vector_float3 {
        let x = particle.initialPosition - source.position
        let r = sqrt(pow(x.x, 2) + pow(x.y, 2))
        let phi: Float = atan2(x.y, x.x)
        let e_r = vector_float3(cos(phi), sin(phi), 0)
        let e_phi = vector_float3(-sin(phi), cos(phi), 0)
        return radialVelocity(r) * e_r + r * angularVelocity(r) * e_phi
    }
    
    public func angularVelocity(_ r: Float) -> Float {
        return particle.angularMomentum / pow(r, 2)
    }
    
    public func effectivePotentialSquared(_ r: Float) -> Float {
        return (1 - 2 * source.mass / r) * (1 + pow(particle.angularMomentum / r, 2))
    }
    
    public func radialVelocity(_ r: Float) -> Float {
        let V_sq = effectivePotentialSquared(r)
        let E_sq = pow(particle.energy, 2)
        guard E_sq > V_sq else { return 0 }
        return -sqrt(E_sq - V_sq)
    }
    
    public func effectiveRadialForce(_ r: Float) -> Float {
        let F_L = pow(particle.angularMomentum / r, 2) / r
        let F_M = -source.mass / pow(r, 2)
        return F_M /*+ F_L*/ + 3 * F_M * F_L * r
    }
}

public struct NewtonGeodesic: Geodesic {
    public let particle: Particle
    public let source: BlackHole
    public let fieldBitMask: UInt32 = newtonCategory
    
    public var initialVelocity: vector_float3 {
        let x = particle.initialPosition - source.position
        let r = sqrt(pow(x.x, 2) + pow(x.y, 2))
        let phi: Float = atan2(x.y, x.x)
        let v = sqrt(2 * (particle.energy - source.mass / r))
        let w = particle.angularMomentum / pow(r, 2)
        let a = Float(asin(w / r / v))
        let b = a + phi
        return Float(v) * vector_float3(cos(b), sin(b), 0)
    }
    
    public func angularVelocity(_ r: Float) -> Float {
        return particle.angularMomentum / pow(r, 2)
    }
    
    public func effectiveRadialForce(_ r: Float) -> Float {
        //let F_L = pow(particle.angularMomentum / r, 2) / r
        let F_M = -source.mass / pow(r, 2)
        return F_M //+ F_L
    }
    
}


public class GeodesicsScene: SKScene {
    
    public var schwarzschildGeodesic: SchwarzschildGeodesic!
    public var newtonGeodesic: NewtonGeodesic!
    
    private var blackholeNode: CelestialBodyNode!
    private var schwarzschildParticleNode: CelestialBodyNode!
    private var newtonParticleNode: CelestialBodyNode!
    private var schwarzschildField: SKFieldNode!
    private var newtonField: SKFieldNode!

    private var backgroundTexture = SKTexture(imageNamed: "milkyway.jpg")
    private var backgroundImage: SKSpriteNode!
    
    override public init() {
        super.init(size: .zero)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.physicsWorld.gravity = .zero
        self.physicsWorld.speed = 3
        
        self.backgroundImage = SKSpriteNode(texture: backgroundTexture)
        self.addChild(backgroundImage)
        
        self.setParameters(blackholeMass: 0.2, angularMomentumMagnitude: 0.5, energyMagnitude: 0) // 0.5, 0.68
        let blackhole = schwarzschildGeodesic.source
        //let particle = schwarzschildGeodesic.particle
        
        //let V = (Int(3*blackhole.mass*10)...Int(30*blackhole.mass*10)).map{ self.schwarzschildGeodesic.effectivePotentialSquared(Float($0) / 10) }
        
        self.schwarzschildParticleNode = CelestialBodyNode(geodesic: schwarzschildGeodesic, color: .white)
        schwarzschildParticleNode.emitterTargetNode = self
        self.addChild(schwarzschildParticleNode)
        self.newtonParticleNode = CelestialBodyNode(geodesic: newtonGeodesic, color: .yellow)
        newtonParticleNode.emitterTargetNode = self
        self.addChild(newtonParticleNode)
        
        self.schwarzschildField = SKFieldNode.customField {
            (position: vector_float3, velocity: vector_float3, mass: Float, charge: Float, deltaTime: TimeInterval) in
            let distance = position - blackhole.position
            let r = sqrt(pow(distance.x, 2) + pow(distance.y, 2))
            let phi = atan2(distance.y, distance.x)
            let F = self.schwarzschildGeodesic.effectiveRadialForce(r)
            //let v = sqrt(pow(Double(velocity.x), 2) + pow(Double(velocity.y), 2))
            //let a = atan2(distance.y, distance.x) - atan2(velocity.y, velocity.x)
            //let w = r * v * Double(sin(a))
            //let L = pow(r, 2) * w
            //return vector_float3(0,0,0)
            //let V = self.schwarzschildGeodesic.effectivePotentialSquared(r)
            let e_r = vector_float3(cos(phi), sin(phi), 0)
            return F * mass * e_r
        }
        schwarzschildField.categoryBitMask = schwarzschildCategory
        schwarzschildField.position = CGPoint(x: CGFloat(blackhole.position.x) * pointsPerMeter, y: CGFloat(blackhole.position.y) * pointsPerMeter)
        self.addChild(schwarzschildField)
        
        self.newtonField = SKFieldNode.customField {
            (position: vector_float3, velocity: vector_float3, mass: Float, charge: Float, deltaTime: TimeInterval) in
            let distance = position - blackhole.position
            let r = sqrt(pow(distance.x, 2) + pow(distance.y, 2))
            let phi = atan2(distance.y, distance.x)
            let F = self.newtonGeodesic.effectiveRadialForce(r)
            //let v = sqrt(pow(Double(velocity.x), 2) + pow(Double(velocity.y), 2))
            //let a = atan2(distance.y, distance.x) - atan2(velocity.y, velocity.x)
            //let w = r * v * Double(sin(a))
            //let L = pow(r, 2) * w
            //return vector_float3(0,0,0)
            let e_r = vector_float3(cos(phi), sin(phi), 0)
            return F * mass * e_r
        }
        newtonField.categoryBitMask = newtonCategory
        newtonField.position = CGPoint(x: CGFloat(blackhole.position.x) * pointsPerMeter, y: CGFloat(blackhole.position.y) * pointsPerMeter)
        //self.addChild(newtonField)
        
        self.blackholeNode = CelestialBodyNode(blackhole: blackhole)
        blackholeNode.position = .zero
        blackholeNode.emitterTargetNode = self
        schwarzschildField.addChild(blackholeNode)
        
        resetPositions()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setParameters(blackholeMass: Float, angularMomentumMagnitude: Float, energyMagnitude: Float) {
        let blackhole = BlackHole(mass: blackholeMass, position: vector_float3(0, 0, 0))
        
        let saddleAngularMomentum = sqrt(12) * blackhole.mass
        let orbitingAngularMomentum = saddleAngularMomentum * 4 / 3.46
        
        let angularMomentum = saddleAngularMomentum + angularMomentumMagnitude * (orbitingAngularMomentum - saddleAngularMomentum) * 2
        
        let initialRadius: Float
        if angularMomentum >= saddleAngularMomentum {
            let circularOrbitRadius = pow(angularMomentum, 2) / 2 / blackhole.mass * (1 + sqrt(1 - 12 * pow(blackhole.mass / angularMomentum, 2)))
            //let innerOrbitRadius = pow(angularMomentum, 2) / 2 / blackhole.mass * (1 - sqrt(1 - 12 * pow(blackhole.mass / angularMomentum, 2)))
            initialRadius = circularOrbitRadius
        } else {
            initialRadius = 12 * blackhole.mass
        }
        
        let radialRestEnergy = sqrt((1 - 2 * blackhole.mass / initialRadius) * (1 + pow(angularMomentum / initialRadius, 2)))
        
        let energy: Float
        if angularMomentum >= saddleAngularMomentum {
            let ellipticOrbitEnergy = radialRestEnergy + (1 - radialRestEnergy) / 10
            let farEllipticOrbitEnergy = radialRestEnergy + (1 - radialRestEnergy) / 2
            let catchEnergy = 1 - (1 - radialRestEnergy) / 3.2595
            let flybyEnergy = 1 - (1 - radialRestEnergy) / 3 // TODO: should be 1 to slightly larger without falling into horizon
            let fallInEnergy: Float = 1
            
            energy = radialRestEnergy + energyMagnitude * (fallInEnergy - radialRestEnergy)
        } else {
            energy = radialRestEnergy + energyMagnitude * radialRestEnergy / 10
        }
        
        let particle = Particle(initialPosition: vector_float3(Float(-initialRadius), 0, 0), energy: energy, angularMomentum: angularMomentum)
        
        self.schwarzschildGeodesic = SchwarzschildGeodesic(particle: particle, source: blackhole)
        self.newtonGeodesic = NewtonGeodesic(particle: particle, source: blackhole)
    }
    
    private func resetPositions() {
        schwarzschildParticleNode.reset(geodesic: schwarzschildGeodesic)
        newtonParticleNode.reset(geodesic: newtonGeodesic)
        resizeViewport()
    }
    
    public func resizeViewport() {
        guard let particle = schwarzschildGeodesic?.particle else { return }
        let viewportRadius = 3 / 2 * CGFloat(sqrt(pow(particle.initialPosition.x, 2) + pow(particle.initialPosition.y, 2))) * pointsPerMeter
        
        self.size = CGSize(width: viewportRadius * 2, height: viewportRadius * 2)
        
        let backgroundSize = backgroundTexture.size()
        let backgroundScale = max(self.size.width / backgroundSize.width, self.size.height / backgroundSize.height)
        backgroundImage.setScale(backgroundScale)
    }
    
    public func startSimulation() {
        schwarzschildField.isEnabled = true
        newtonField.isEnabled = true
    }
    
    public func stopSimulation() {
        schwarzschildField.isEnabled = false
        newtonField.isEnabled = false
        if case .none = schwarzschildParticleNode.parent {
            self.addChild(schwarzschildParticleNode)
        }
        if case .none = newtonParticleNode.parent {
            self.addChild(newtonParticleNode)
        }
        resetPositions()
    }
    
    override public func update(_ currentTime: TimeInterval) {
        if case .some = schwarzschildParticleNode.parent {
            let r = sqrt(pow(Float(schwarzschildParticleNode.position.x / pointsPerMeter), 2) + pow(Float(schwarzschildParticleNode.position.y / pointsPerMeter), 2))
            if r <= 3 * schwarzschildGeodesic.source.mass {
                schwarzschildParticleNode.removeFromParent()
                blackholeNode.emitMergeEffect()
            }
        }
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
        let angularMomentumMagnitude = Float((location.x + size.width / 2) / size.width)
        let energyMagnitude = Float((location.y + size.height / 2) / size.height)
        setParameters(blackholeMass: schwarzschildGeodesic.source.mass, angularMomentumMagnitude: angularMomentumMagnitude, energyMagnitude: energyMagnitude)
        resetPositions()
    }
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        startSimulation()
    }
    
}

public class GeodesicsViewController: UIViewController {
    
    private let simulationView = SKView(frame: .zero)
    private let simulationScene = GeodesicsScene()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(simulationView)
        simulationScene.scaleMode = .aspectFill
        simulationView.presentScene(simulationScene)
        simulationScene.startSimulation()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        simulationView.frame = view.bounds
    }
    
}
