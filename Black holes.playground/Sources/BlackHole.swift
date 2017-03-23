import PlaygroundSupport
import SpriteKit


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
    
    // MARK: Playground communication
    
//    private static let massKey = "mass"
//    private static let positionKey = "position"
//    
//    public init(playgroundValue: PlaygroundValue) {
//        guard case let .dictionary(dict) = playgroundValue else {
//            self.init()
//            return
//        }
//        guard case let .floatingPoint(mass)? = dict[BlackHole.massKey] else {
//            self.init()
//            return
//        }
//        guard case let .string(encodedPosition)? = dict[BlackHole.positionKey] else {
//            self.init()
//            return
//        }
//        let positionComponents = encodedPosition.components(separatedBy: ",").flatMap({ Float($0) })
//        guard positionComponents.count == 3 else {
//            self.init()
//            return
//        }
//        self.init(mass: mass, position: vector_float3(positionComponents[0], positionComponents[1], positionComponents[2]))
//    }
//    
//    var playgroundValue: PlaygroundValue {
//        return .dictionary([
//            BlackHole.massKey: .floatingPoint(mass),
//            BlackHole.positionKey: .string([ position.x, position.y, position.z ].joined(separator: ","))
//            ])
//    }
}
