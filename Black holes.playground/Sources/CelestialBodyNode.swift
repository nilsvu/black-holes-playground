import SpriteKit


public let pointsPerMeter: CGFloat = 150
private let roundParticle = SKTexture(imageNamed: "round_particle.png")

public class CelestialBodyNode: SKShapeNode {
    
    public private(set) var auraEffectEmitter: SKEmitterNode?
    public private(set) var mergeEffectEmitter: SKEmitterNode?
    public private(set) var traceEffectEmitter: SKEmitterNode?
    
    public init(blackhole: BlackHole) {
        super.init()
        let radius = blackhole.schwarzschildRadius
        let scaledRadius = CGFloat(radius) * pointsPerMeter
        self.path = CGPath(ellipseIn: CGRect(x: -scaledRadius, y: -scaledRadius, width: 2 * scaledRadius, height: 2 * scaledRadius), transform: nil)
        self.fillColor = .black
        self.strokeColor = .clear
        
        let auraEffectEmitter: SKEmitterNode = {
            let emitter = SKEmitterNode()
            emitter.name = "auraEffectEmitter"
            emitter.particleBirthRate = 30
            emitter.particleLifetime = 2
            emitter.particleLifetimeRange = 0.2
            emitter.particleSize = CGSize(width: 14, height: 14)
            emitter.particleTexture = roundParticle
            emitter.particleColorBlendFactor = 1
            emitter.particleColor = .black
            emitter.particlePositionRange = CGVector(dx: 2 * scaledRadius, dy: 2 * scaledRadius)
            emitter.emissionAngleRange = 2 * .pi
            emitter.particleAlpha = 0
            emitter.particleAlphaSpeed = 1 / 0.2
            emitter.particleSpeed = -10 / emitter.particleLifetime
            emitter.particleSpeedRange = 5
            emitter.position = .zero
            emitter.particleScaleRange = 0.3
            emitter.particleScaleSpeed = -1 / emitter.particleLifetime
            return emitter
        }()
        self.addChild(auraEffectEmitter)
        self.auraEffectEmitter = auraEffectEmitter

        let mergeEffectEmitter: SKEmitterNode = {
            let emitter = SKEmitterNode()
            emitter.numParticlesToEmit = 50
            emitter.particleBirthRate = 200
            emitter.particleLifetime = 1
            emitter.particleLifetimeRange = 0.1
            emitter.particleSize = CGSize(width: 14, height: 14)
            emitter.particleTexture = roundParticle
            emitter.particleColorBlendFactor = 1
            emitter.particleColor = .black // TODO: bunt?
            emitter.emissionAngleRange = 2 * .pi
            emitter.particleAlphaSpeed = -0.5 / emitter.particleLifetime
            emitter.particleSpeed = 3 * scaledRadius / emitter.particleLifetime
            emitter.particleSpeedRange = emitter.particleSpeed / 5
            emitter.position = .zero
            emitter.particleScaleRange = 0.3
            emitter.particleScaleSpeed = -1 / emitter.particleLifetime
            return emitter
        }()
        self.mergeEffectEmitter = mergeEffectEmitter
        mergeEffectEmitter.advanceSimulationTime(TimeInterval(mergeEffectEmitter.particleLifetime))
        self.addChild(mergeEffectEmitter)
    }
    
    public init(geodesic: Geodesic, color: UIColor) {
        super.init()
        self.fillColor = color
        self.strokeColor = .clear
        
        self.reset(geodesic: geodesic)
        
        let traceEffectEmitter: SKEmitterNode = {
            let emitter = SKEmitterNode()
            let lifetime: CGFloat = 20
            emitter.particleBirthRate = 10
            emitter.particleLifetime = lifetime
            //emitter.particleLifetimeRange = 0.1
            emitter.particleSize = CGSize(width: 3, height: 3)
            //emitter.particleTexture = roundParticle
            //emitter.particleColorBlendFactor = 1
            //emitter.particleColorSequence = nil
            //emitter.particleColorBlendFactorSequence = nil
            emitter.particleColor = color
            emitter.emissionAngleRange = 2 * .pi
            emitter.particleAlphaSpeed = -1 / lifetime
            emitter.particleSpeed = 50 / lifetime
            emitter.particleSpeedRange = 20 / lifetime
            emitter.position = .zero
            emitter.particleScaleRange = 0.3
            emitter.particleScaleSpeed = -1 / lifetime
            return emitter
        }()
        self.traceEffectEmitter = traceEffectEmitter
        self.addChild(traceEffectEmitter)
    }
    
    public func reset(geodesic: Geodesic) {
        let radius = geodesic.source.mass / 3
        let scaledRadius = CGFloat(radius) * pointsPerMeter
        self.path = CGPath(ellipseIn: CGRect(x: -scaledRadius, y: -scaledRadius, width: 2 * scaledRadius, height: 2 * scaledRadius), transform: nil)
        
        let physicsBody = SKPhysicsBody(circleOfRadius: CGFloat(radius) * pointsPerMeter)
        physicsBody.mass = 1
        physicsBody.friction = 0
        physicsBody.allowsRotation = false
        physicsBody.linearDamping = 0
        physicsBody.angularDamping = 0
        physicsBody.fieldBitMask = geodesic.fieldBitMask
        
        let initialPosition = geodesic.particle.initialPosition
        self.position = CGPoint(x: CGFloat(initialPosition.x) * pointsPerMeter, y: CGFloat(initialPosition.y) * pointsPerMeter)
        
        let initialVelocity = geodesic.initialVelocity
        physicsBody.velocity = CGVector(dx: CGFloat(initialVelocity.x) * pointsPerMeter, dy: CGFloat(initialVelocity.y) * pointsPerMeter)
        
        self.physicsBody = physicsBody
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func emitMergeEffect() {
        mergeEffectEmitter?.resetSimulation()
        mergeEffectEmitter?.advanceSimulationTime(TimeInterval(mergeEffectEmitter?.particleLifetime ?? 0) / 2)
    }
    
    public var emitterTargetNode: SKNode? {
        get {
            return nil // unnecessary
        } set {
            auraEffectEmitter?.targetNode = newValue
            mergeEffectEmitter?.targetNode = newValue
            traceEffectEmitter?.targetNode = newValue
        }
    }
    
    public override func removeFromParent() {
        auraEffectEmitter?.resetSimulation()
        mergeEffectEmitter?.resetSimulation()
        traceEffectEmitter?.resetSimulation()
        super.removeFromParent()
    }
}
