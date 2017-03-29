/*
 CelestialBodyNode.swift
 
 Author: [Nils Leif Fischer](http://nilsleiffischer.de/)
*/

import SpriteKit


public let pointsPerMeter: CGFloat = 150
private let roundParticleBlack = SKTexture(imageNamed: "round_particle@2x.png")
private let roundParticleWhite = SKTexture(imageNamed: "round_particle_white@2x.png")
private let roundParticleYellow = SKTexture(imageNamed: "round_particle_yellow@2x.png")


/// A node that visually represents a black hole or a test particle in a simulation.
public class CelestialBodyNode: SKShapeNode {
    
    public private(set) var auraEffectEmitter: SKEmitterNode?
    public private(set) var mergeEffectEmitter: SKEmitterNode?
    public private(set) var traceEffectEmitter: SKEmitterNode?
    
    private var radiusScale: CGFloat
    
    public init(blackhole: BlackHole, scale: CGFloat = 1) {
        self.radiusScale = scale
        super.init()
        let radius = blackhole.schwarzschildRadius
        let scaledRadius = CGFloat(radius) * pointsPerMeter * radiusScale
        self.path = CGPath(ellipseIn: CGRect(x: -scaledRadius, y: -scaledRadius, width: 2 * scaledRadius, height: 2 * scaledRadius), transform: nil)
        self.fillColor = .black
        self.strokeColor = .clear
        
        let auraEffectEmitter: SKEmitterNode = {
            let emitter = SKEmitterNode()
            emitter.name = "auraEffectEmitter"
            emitter.particleBirthRate = 30
            emitter.particleLifetime = 2
            emitter.particleLifetimeRange = 0.2
            emitter.particleSize = CGSize(width: 14 * radiusScale, height: 14 * radiusScale)
            emitter.particleTexture = roundParticleBlack
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
            emitter.particleSize = CGSize(width: 14 * radiusScale, height: 14 * radiusScale)
            emitter.particleTexture = roundParticleBlack
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
    
    public init(geodesic: Geodesic, color: UIColor, scale: CGFloat = 1) {
        self.radiusScale = scale
        super.init()
        self.fillColor = color
        self.strokeColor = .clear
        
        let traceEffectEmitter: SKEmitterNode = {
            let emitter = SKEmitterNode()
            emitter.particleBirthRate = 50
            emitter.particleLifetime = 20
            if color == .white {
                emitter.particleTexture = roundParticleWhite
            } else if color == .yellow {
                emitter.particleTexture = roundParticleYellow
            }
            emitter.emissionAngleRange = 2 * .pi
            emitter.particleAlphaSpeed = -1 / emitter.particleLifetime
            emitter.particleAlphaRange = 0.5
            emitter.position = .zero
            emitter.particleScaleRange = 0.5
            emitter.particleScaleSpeed = -1 / emitter.particleLifetime
            return emitter
        }()
        self.traceEffectEmitter = traceEffectEmitter
        self.addChild(traceEffectEmitter)

        self.reset(geodesic: geodesic)
    }
    
    public func reset(geodesic: Geodesic, scale: CGFloat = 1) {
        self.radiusScale = scale
        let scaledRadius = 10 * radiusScale
        self.path = CGPath(ellipseIn: CGRect(x: -scaledRadius, y: -scaledRadius, width: 2 * scaledRadius, height: 2 * scaledRadius), transform: nil)
        
        if let emitter = self.traceEffectEmitter {
            emitter.particleSize = CGSize(width: 5 * radiusScale, height: 5 * radiusScale)
            emitter.particleSpeed = 5 * scaledRadius / emitter.particleLifetime
            emitter.particleSpeedRange = emitter.particleSpeed / 5
        }
        
        let physicsBody = SKPhysicsBody(circleOfRadius: scaledRadius)
        physicsBody.mass = 1
        physicsBody.friction = 0
        physicsBody.allowsRotation = false
        physicsBody.linearDamping = 0
        physicsBody.angularDamping = 0
        physicsBody.fieldBitMask = geodesic.fieldBitMask
        physicsBody.collisionBitMask = 0
        
        let initialVelocity = geodesic.initialVelocity
        physicsBody.velocity = CGVector(dx: CGFloat(initialVelocity.x) * pointsPerMeter, dy: CGFloat(initialVelocity.y) * pointsPerMeter)
        
        self.physicsBody = physicsBody
        
        let initialPosition = geodesic.particle.initialPosition
        self.position = CGPoint(x: CGFloat(initialPosition.x) * pointsPerMeter, y: CGFloat(initialPosition.y) * pointsPerMeter)

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
    
    public func disableAura() {
        self.auraEffectEmitter?.removeFromParent()
        self.auraEffectEmitter = nil
    }
    
    public func pauseTrace() {
        self.traceEffectEmitter?.particleBirthRate = 0
    }
    public func unpauseTrace() {
        self.traceEffectEmitter?.particleBirthRate = 50
    }
    
    public override func removeFromParent() {
        auraEffectEmitter?.resetSimulation()
        mergeEffectEmitter?.resetSimulation()
        traceEffectEmitter?.resetSimulation()
        super.removeFromParent()
    }
}
