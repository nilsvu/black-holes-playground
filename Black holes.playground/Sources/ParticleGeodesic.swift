import PlaygroundSupport
import SpriteKit

public struct Particle {
    public let initialPosition: vector_float3
    public let energy: Float
    public let angularMomentum: Float
    
    public init(initialPosition: vector_float3, energy: Float, angularMomentum: Float) {
        self.initialPosition = initialPosition
        self.energy = energy
        self.angularMomentum = angularMomentum
    }
}

public protocol Geodesic {
    var particle: Particle { get }
    var source: BlackHole { get }
    var fieldBitMask: UInt32 { get }
    var initialVelocity: vector_float3 { get }
    func effectiveRadialForce(_ r: Float) -> Float
}
