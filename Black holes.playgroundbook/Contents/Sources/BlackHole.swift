/*
 BlackHole.swift
 
 Author: [Nils Leif Fischer](http://nilsleiffischer.de/)
*/

import SpriteKit

/// A Schwarzschild black hole in general relativity
public struct BlackHole {
    
    /// Mass of the black hole in solar masses
    public let mass: Float
    /// Position of the black hole in cosmic coordinates
    public let position: vector_float3
    /// The Schwarzschild radius is the minimum distance to the black holes that still allows objects to escape.
    public var schwarzschildRadius: Float {
        return 2 * mass
    }
    
    public init(mass: Float = 1, position: vector_float3 = vector_float3(0, 0, 0)) {
        self.mass = mass
        self.position = position
    }
}
