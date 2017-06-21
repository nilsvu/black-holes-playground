/*
 GeodesicsViewController.swift

 Author: [Nils Leif Fischer](http://nilsleiffischer.de/)
*/

import UIKit
import SpriteKit


private let schwarzschildCategory: UInt32 = 0x1 << 1
private let newtonCategory: UInt32 = 0x1 << 2

private let particleZPosition: CGFloat = 100
private let blackholeZPosition: CGFloat = 50
private let traceZPosition: CGFloat = 25
private let labelZPosition: CGFloat = 150


/// The trajectory a test particle follows in the presence of a spherically symmetric source in general relativity
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
        let F_M = -source.mass / pow(r, 2)
        return F_M /*+ F_L*/ + 3 * F_M * pow(particle.angularMomentum / r, 2)
    }
}

/// The trajectory a test particle follows in the presence of a spherically symmetric source in Newtonian gravity
public struct NewtonGeodesic: Geodesic {
    public let particle: Particle
    public let source: BlackHole
    public let fieldBitMask: UInt32 = newtonCategory

    public var initialVelocity: vector_float3 {
        let x = particle.initialPosition - source.position
        let r = sqrt(pow(x.x, 2) + pow(x.y, 2))
        let phi: Float = atan2(x.y, x.x)
        return radialVelocity(r) * vector_float3(cos(phi), sin(phi), 0) + r * angularVelocity(r) * vector_float3(-sin(phi), cos(phi), 0)
    }

    public func angularVelocity(_ r: Float) -> Float {
        return particle.angularMomentum / pow(r, 2)
    }

    public func effectivePotential(_ r: Float) -> Float {
        return pow(particle.angularMomentum / r, 2) / 2 - source.mass / r + 1
    }

    public func radialVelocity(_ r: Float) -> Float {
        let E = particle.energy
        let V = effectivePotential(r)
        guard E > V else { return 0 }
        return -sqrt(2 * E - 2 * V)
    }

    public func effectiveRadialForce(_ r: Float) -> Float {
        let F_M = -source.mass / pow(r, 2)
        return F_M
    }

}


/// Simulate a spherically symmetric source and test particles that trace geodesics in its presence.
public class GeodesicsScene: SKScene {

    public var schwarzschildGeodesic: SchwarzschildGeodesic!
    public var newtonGeodesic: NewtonGeodesic!
    private let simulationSpeedScale: CGFloat = 0.5 // seconds for initial radius crossing
    private var simulationSpeed: CGFloat = 1
    private var objectScale: CGFloat = 1

    private var blackholeNode: CelestialBodyNode!
    private var schwarzschildParticleNode: CelestialBodyNode!
    private var newtonParticleNode: CelestialBodyNode!
    private var schwarzschildField: SKFieldNode!
    private var newtonField: SKFieldNode!

    private var backgroundTexture = SKTexture(imageNamed: "milkyway.jpg")
    private var backgroundImage: SKSpriteNode!

    private var trajectoryLabel: SKLabelNode!
    private var legendSchwarzschildLabel: SKLabelNode!
    private var legendNewtonLabel: SKLabelNode!
    private var energyMagnitudeLabel: SKLabelNode!
    private var angularMomentumMagnitudeLabel: SKLabelNode!


    // MARK: Initialization

    override public init() {
        super.init(size: .zero)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.physicsWorld.gravity = .zero

        // Background
        self.backgroundImage = SKSpriteNode(texture: backgroundTexture)
        backgroundImage.zPosition = 0
        self.addChild(backgroundImage)

        // Labels
        let systemFontName = UIFont.boldSystemFont(ofSize: 18).fontName

        self.trajectoryLabel = SKLabelNode(fontNamed: systemFontName)
        trajectoryLabel.fontSize = 76
        trajectoryLabel.fontColor = .white
        trajectoryLabel.zPosition = labelZPosition
        trajectoryLabel.position = .zero
        self.addChild(trajectoryLabel)

        self.legendSchwarzschildLabel = SKLabelNode(fontNamed: systemFontName)
        legendSchwarzschildLabel.fontSize = 36
        legendSchwarzschildLabel.fontColor = .white
        legendSchwarzschildLabel.zPosition = labelZPosition
        legendSchwarzschildLabel.horizontalAlignmentMode = .right
        legendSchwarzschildLabel.verticalAlignmentMode = .top
        legendSchwarzschildLabel.text = "Schwarzschild"
        self.addChild(legendSchwarzschildLabel)

        self.legendNewtonLabel = SKLabelNode(fontNamed: systemFontName)
        legendNewtonLabel.fontSize = 36
        legendNewtonLabel.fontColor = .yellow
        legendNewtonLabel.zPosition = labelZPosition
        legendNewtonLabel.horizontalAlignmentMode = .right
        legendNewtonLabel.verticalAlignmentMode = .top
        legendNewtonLabel.text = "Newton"
        self.addChild(legendNewtonLabel)

        self.energyMagnitudeLabel = SKLabelNode(fontNamed: systemFontName)
        energyMagnitudeLabel.fontSize = 36
        energyMagnitudeLabel.fontColor = .white
        energyMagnitudeLabel.zPosition = labelZPosition
        energyMagnitudeLabel.isHidden = true
        energyMagnitudeLabel.verticalAlignmentMode = .top
        self.addChild(energyMagnitudeLabel)

        self.angularMomentumMagnitudeLabel = SKLabelNode(fontNamed: systemFontName)
        angularMomentumMagnitudeLabel.fontSize = 36
        angularMomentumMagnitudeLabel.fontColor = .white
        angularMomentumMagnitudeLabel.zPosition = labelZPosition
        angularMomentumMagnitudeLabel.isHidden = true
        angularMomentumMagnitudeLabel.verticalAlignmentMode = .bottom
        self.addChild(angularMomentumMagnitudeLabel)

        // Initial parameters
        self.setParameters(blackholeMass: 0.2, angularMomentumMagnitude: 0.5, energyMagnitude: 0.25)
        let blackhole = schwarzschildGeodesic.source

        // Particle nodes
        self.schwarzschildParticleNode = CelestialBodyNode(geodesic: schwarzschildGeodesic, color: .white, scale: objectScale)
        schwarzschildParticleNode.zPosition = particleZPosition
        schwarzschildParticleNode.emitterTargetNode = self
        schwarzschildParticleNode.traceEffectEmitter?.particleZPosition = traceZPosition
        self.addChild(schwarzschildParticleNode)
        self.newtonParticleNode = CelestialBodyNode(geodesic: newtonGeodesic, color: .yellow, scale: objectScale)
        newtonParticleNode.zPosition = particleZPosition
        newtonParticleNode.emitterTargetNode = self
        newtonParticleNode.traceEffectEmitter?.particleZPosition = traceZPosition
        self.addChild(newtonParticleNode)

        // Field nodes
        self.schwarzschildField = SKFieldNode.customField {
            (position: vector_float3, velocity: vector_float3, mass: Float, charge: Float, deltaTime: TimeInterval) in
            let distance = position - blackhole.position
            let r = sqrt(pow(distance.x, 2) + pow(distance.y, 2))
            let phi = atan2(distance.y, distance.x)
            let F = self.schwarzschildGeodesic.effectiveRadialForce(r)
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
            let e_r = vector_float3(cos(phi), sin(phi), 0)
            return F * mass * e_r
        }
        newtonField.categoryBitMask = newtonCategory
        newtonField.position = CGPoint(x: CGFloat(blackhole.position.x) * pointsPerMeter, y: CGFloat(blackhole.position.y) * pointsPerMeter)
        self.addChild(newtonField)

        // Black hole node
        self.blackholeNode = CelestialBodyNode(blackhole: blackhole)
        blackholeNode.position = .zero
        blackholeNode.zPosition = blackholeZPosition
        blackholeNode.emitterTargetNode = self
        schwarzschildField.addChild(blackholeNode)

        resetPositions()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Parameter computation

    /// Sets appropriate initial conditions for the test particles given an angular momentum and energy magnitude from 0 to 1, so that the features of the effective gravitational potential are exhibited.
    public func setParameters(blackholeMass: Float, angularMomentumMagnitude: Float, energyMagnitude: Float) {
        let blackhole = BlackHole(mass: blackholeMass, position: vector_float3(0, 0, 0))

        let saddleAngularMomentum = sqrt(12) * blackhole.mass

        // Select angular momentum
        let angularMomentum = saddleAngularMomentum + angularMomentumMagnitude * 6 * blackhole.mass

        let newtonianCircularOrbitRadius: Float = pow(angularMomentum, 2) / blackhole.mass
        let newtonianCircularOrbitEnergy = pow(angularMomentum / newtonianCircularOrbitRadius, 2) / 2 - blackhole.mass / newtonianCircularOrbitRadius + 1

        // angularMomentum > saddleAngularMomentum
        let schwarzschildCircularOrbitRadius = pow(angularMomentum, 2) / 2 / blackhole.mass * (1 + sqrt(1 - 12 * pow(blackhole.mass / angularMomentum, 2)))
        let initialRadius = schwarzschildCircularOrbitRadius

        let innerOrbitRadius = pow(angularMomentum, 2) / 2 / blackhole.mass * (1 - sqrt(1 - 12 * pow(blackhole.mass / angularMomentum, 2)))
        let schwarzschildCircularOrbitEnergy = sqrt((1 - 2 * blackhole.mass / initialRadius) * (1 + pow(angularMomentum / initialRadius, 2)))
        let innerOrbitEnergy = sqrt((1 - 2 * blackhole.mass / innerOrbitRadius) * (1 + pow(angularMomentum / innerOrbitRadius, 2)))
        let innerOrbitEnergyMagnitude: Float = 0.8

        // Select energy
        let energy: Float
        if energyMagnitude <= innerOrbitEnergyMagnitude {
            energy = schwarzschildCircularOrbitEnergy + pow(energyMagnitude / innerOrbitEnergyMagnitude, 5) * (innerOrbitEnergy - schwarzschildCircularOrbitEnergy)
        } else {
            energy = innerOrbitEnergy + pow((energyMagnitude - innerOrbitEnergyMagnitude) / (1 - innerOrbitEnergyMagnitude), 5) * (innerOrbitEnergy - 1)
        }

        trajectoryLabel.text = {
            switch energy {
            case 0...(schwarzschildCircularOrbitEnergy + (1 - schwarzschildCircularOrbitEnergy) / 5): return "Near-circular orbit! 🌎"
            case (schwarzschildCircularOrbitEnergy + (1 - schwarzschildCircularOrbitEnergy) / 5)...1: return "Elliptic orbit! ☄️"
            case 1...(innerOrbitEnergy - (innerOrbitEnergy - 1) / 6): return "Fly-by! ☄️"
            case (innerOrbitEnergy - (innerOrbitEnergy - 1) / 6)...(innerOrbitEnergy + (innerOrbitEnergy - 1) / 6): return "Near-catch! 💫"
            default: return "Fall-in! 💥"
            }
        }()

        self.objectScale = CGFloat(initialRadius / pow(saddleAngularMomentum, 2) * blackhole.mass)

        let particle = Particle(initialPosition: vector_float3(Float(-initialRadius), 0, 0), energy: energy, angularMomentum: angularMomentum)

        self.schwarzschildGeodesic = SchwarzschildGeodesic(particle: particle, source: blackhole)
        self.newtonGeodesic = NewtonGeodesic(particle: particle, source: blackhole)
    }


    // MARK: Simulation control

    public func startSimulation() {
        resetPositions()
        let simulationTimescale = (newtonGeodesic.particle.initialPosition - newtonGeodesic.source.position).magnitude / newtonGeodesic.initialVelocity.magnitude
        self.simulationSpeed = CGFloat(simulationTimescale) / simulationSpeedScale
        self.physicsWorld.speed = simulationSpeed
        trajectoryLabel.removeAllActions()
        trajectoryLabel.alpha = 0
        trajectoryLabel.isHidden = false
        trajectoryLabel.setScale(self.objectScale / 2)
        trajectoryLabel.run(.sequence([
            .wait(forDuration: TimeInterval(3 * self.simulationSpeedScale)),
            .group([
                .scale(to: self.objectScale, duration: 0.2),
                .fadeIn(withDuration: 0.2),
                ]),
            .wait(forDuration: TimeInterval(self.simulationSpeedScale)),
            .group([
                .scale(to: self.objectScale / 2, duration: 0.2),
                .fadeOut(withDuration: 0.2),
                ]),
            .hide()
            ]))
        schwarzschildParticleNode.unpauseTrace()
        newtonParticleNode.unpauseTrace()
    }

    public func stopSimulation() {
        self.physicsWorld.speed = 0
        if case .none = schwarzschildParticleNode.parent {
            self.addChild(schwarzschildParticleNode)
        }
        if case .none = newtonParticleNode.parent {
            self.addChild(newtonParticleNode)
        }
        schwarzschildParticleNode.pauseTrace()
        newtonParticleNode.pauseTrace()
        trajectoryLabel.isHidden = true
        resetPositions()
    }

    private func resetPositions() {
        schwarzschildParticleNode.reset(geodesic: schwarzschildGeodesic, scale: objectScale)
        newtonParticleNode.reset(geodesic: newtonGeodesic, scale: objectScale)
        resizeViewport()
    }

    public func resizeViewport(ratio: CGFloat? = nil) {
        let viewportRatio: CGFloat
        if let ratio = ratio {
            viewportRatio = ratio
        } else if self.size != .zero {
            viewportRatio = self.size.width / self.size.height
        } else {
            viewportRatio = 1
        }
        guard let particle = schwarzschildGeodesic?.particle else { return }
        let viewportRadius = 3 / 2 * CGFloat(sqrt(pow(particle.initialPosition.x, 2) + pow(particle.initialPosition.y, 2))) * pointsPerMeter

        self.size = CGSize(width: 2 * viewportRadius * max(1, viewportRatio), height: 2 * viewportRadius * max(1, 1 / viewportRatio))
        energyMagnitudeLabel.setScale(self.objectScale)
        angularMomentumMagnitudeLabel.setScale(self.objectScale)

        let backgroundSize = backgroundTexture.size()
        let backgroundScale = max(self.size.width / backgroundSize.width, self.size.height / backgroundSize.height)
        backgroundImage.setScale(backgroundScale)

        legendNewtonLabel.setScale(self.objectScale)
        legendSchwarzschildLabel.setScale(self.objectScale)
        let legendOffset = 30 * self.objectScale
        let legendVerticalDistance = 70 * self.objectScale
        legendSchwarzschildLabel.position = CGPoint(x: self.size.width / 2 - legendOffset, y: self.size.height / 2 - legendOffset)
        legendNewtonLabel.position = CGPoint(x: self.size.width / 2 - legendOffset, y: self.size.height / 2 - legendOffset - legendVerticalDistance)
    }


    // MARK: Update loop

    override public func update(_ currentTime: TimeInterval) {
        // Merge particles that fall into the black hole
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
        energyMagnitudeLabel.isHidden = false
        angularMomentumMagnitudeLabel.isHidden = false
    }
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeTouch = self.activeTouch, touches.contains(activeTouch) else { return }
        let location = activeTouch.location(in: self)
        let angularMomentumMagnitude = max(0, min(1, Float((location.x + size.width / 2) / size.width)))
        let energyMagnitude = max(0, min(1, Float((location.y + size.height / 2) / size.height)))
        setParameters(blackholeMass: schwarzschildGeodesic.source.mass, angularMomentumMagnitude: angularMomentumMagnitude, energyMagnitude: energyMagnitude)
        resetPositions()
        showInitialVelocity(geodesic: schwarzschildGeodesic, particleNode: schwarzschildParticleNode)
        showInitialVelocity(geodesic: newtonGeodesic, particleNode: newtonParticleNode)

        angularMomentumMagnitudeLabel.text = "\(Int(round(angularMomentumMagnitude * 100)))% angularMomentum"
        energyMagnitudeLabel.text = "\(Int(round(energyMagnitude * 100)))% energy"
        let horizontalAlignmentMode: SKLabelHorizontalAlignmentMode = angularMomentumMagnitude > 0.5 ? .right : .left
        energyMagnitudeLabel.horizontalAlignmentMode = horizontalAlignmentMode
        angularMomentumMagnitudeLabel.horizontalAlignmentMode = horizontalAlignmentMode
        let fingerAreaHorizontalOffset = self.objectScale * 120 * (angularMomentumMagnitude > 0.5 ? -1 : 1)
        let verticalDistance = self.objectScale * 40
        angularMomentumMagnitudeLabel.position = CGPoint(x: location.x + fingerAreaHorizontalOffset, y: location.y + verticalDistance / 2)
        energyMagnitudeLabel.position = CGPoint(x: location.x + fingerAreaHorizontalOffset, y: location.y - verticalDistance / 2)
    }
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        energyMagnitudeLabel.isHidden = true
        angularMomentumMagnitudeLabel.isHidden = true
        startSimulation()
        hideInitialVelocity()
    }

    private func showInitialVelocity(geodesic: Geodesic, particleNode: CelestialBodyNode) {
        let initialVelocity = geodesic.initialVelocity
        let arrowUnitLength = objectScale * pointsPerMeter * 5
        let arrowEndpoint = CGPoint(x: CGFloat(initialVelocity.x) * arrowUnitLength, y: CGFloat(initialVelocity.y) * arrowUnitLength)
        let arrowAngle: CGFloat = .pi / 4
        let velocityAngle = CGFloat(atan2(initialVelocity.y, initialVelocity.x))
        let firstArmAngle: CGFloat = velocityAngle + .pi / 2 + arrowAngle
        let secondArmAngle: CGFloat = velocityAngle - .pi / 2 - arrowAngle
        let arrowArmLength: CGFloat = arrowUnitLength / 20
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: arrowEndpoint)
        path.addLine(to: CGPoint(x: arrowEndpoint.x + arrowArmLength * cos(firstArmAngle), y: arrowEndpoint.y + arrowArmLength * sin(firstArmAngle)))
        path.move(to: arrowEndpoint)
        path.addLine(to: CGPoint(x: arrowEndpoint.x + arrowArmLength * cos(secondArmAngle), y: arrowEndpoint.y + arrowArmLength * sin(secondArmAngle)))

        if let existingVelocityVisualization = particleNode.childNode(withName: "velocityVisualization") as? SKShapeNode {
            existingVelocityVisualization.path = path
        } else {
            let shape = SKShapeNode(path: path)
            shape.lineJoin = .round
            shape.lineCap = .round
            shape.fillColor = .clear
            if particleNode === newtonParticleNode {
                shape.strokeColor = .yellow
            } else {
                shape.strokeColor = .white
            }
            shape.name = "velocityVisualization"
            particleNode.addChild(shape)
        }
        (particleNode.childNode(withName: "velocityVisualization") as? SKShapeNode)?.lineWidth = 4 * objectScale
    }

    private func hideInitialVelocity() {
        schwarzschildParticleNode?.childNode(withName: "velocityVisualization")?.removeFromParent()
        newtonParticleNode?.childNode(withName: "velocityVisualization")?.removeFromParent()
    }

}


// MARK: View controller wrapper

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
        simulationScene.resizeViewport(ratio: view.bounds.width / view.bounds.height)
    }

}
