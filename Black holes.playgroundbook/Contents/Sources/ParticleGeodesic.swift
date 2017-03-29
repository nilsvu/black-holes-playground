/*
 ParticleGeodesic.swift
 
 Author: [Nils Leif Fischer](http://nilsleiffischer.de/)
*/

import PlaygroundSupport
import SpriteKit

/// A test particle with initial conditions given by position, energy and angular momentum
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

/// The trajectory of a test particle in the presence of a spherically symmetric source.
public protocol Geodesic {
    var particle: Particle { get }
    var source: BlackHole { get }
    var fieldBitMask: UInt32 { get }
    var initialVelocity: vector_float3 { get }
    func effectiveRadialForce(_ r: Float) -> Float
}
