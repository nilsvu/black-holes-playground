//#-hidden-code
//
//  Contents.swift
//
//  Copyright (c) 2017 Nils Leif Fischer. All Rights Reserved.
//

import UIKit
import PlaygroundSupport

func simulate(_ binarySystem: BinarySystem) {
    
}
//#-end-hidden-code
/*:
 ## Gravitational waves
 
 Since black holes are by their very nature invisible to telescopes, the only way to directly detect them is by their gravitational interaction. Often we can infer the existence of a black hole from the visible objects orbiting it, such as stars that orbit a supermassive black hole in the center of a galaxy. It was not until September 2015, however, that we could observe a signal that was emitted by black holes directly.
 
 The LIGO gravitational wave observatories in Louisiana and Washington both detected a tiny shift in the lengths of their two L-shaped arms that are continously measured by lasers to extreme precision. This change in length was caused by two massive black holes that rotated around each other and merged to one in an event that happened more than one billion years ago. This process violently distorted spacetime in its vicinity and these distortions traveled towards us as gravitational waves at the speed of light, causing a periodical signal of minute changes in measured distance on earth.
 
 ---
 
 In this simulation you can watch two black holes merge and hear the gravitational waves they produce in the process.
 
 Slide horizontally to adjust the mass ratio of the two black holes and vertically to adjust their total mass. Listen carefully. How do the two parameters influence the gravitational wave signal of the merger? It is this information that allows gravitational wave astronomers to deduce the parameters of the signal's source from their observation.
*/
let binarySystem = BinarySystem(firstMass: /*#-editable-code*/1/*#-end-editable-code*/, secondMass: /*#-editable-code*/1/*#-end-editable-code*/)
simulate(binarySystem)
/*
 ### References
 
 - Discovery of the first gravitational wave signal: [Observation of Gravitational Waves from a Binary Black Hole Merger (2016)](http://journals.aps.org/prl/abstract/10.1103/PhysRevLett.116.061102), LIGO Scientific Collaboration and Virgo Collaboration
*/
