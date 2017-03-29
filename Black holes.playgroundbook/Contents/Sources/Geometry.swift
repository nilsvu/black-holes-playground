/*
 Geometry.swift
 
 Author: [Nils Leif Fischer](http://nilsleiffischer.de/)
*/

import SpriteKit

extension vector_float3 {
    
    public var magnitude: Float {
        return sqrt(pow(x, 2) + pow(y, 2) + pow(z, 2))
    }

    public var azimuth: Float { // TODO
        return atan2(y, x)
    }

}
