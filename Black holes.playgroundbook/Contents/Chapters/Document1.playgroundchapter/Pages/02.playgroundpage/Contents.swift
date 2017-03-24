//#-hidden-code
//
//  Contents.swift
//
//  Copyright (c) 2017 Nils Leif Fischer. All Rights Reserved.
//

import UIKit
import PlaygroundSupport

func applyLens(to source: UIImage) {
    
}
//#-end-hidden-code
/*:
 ## Gravitational lensing
 
 Since not only massive particles but also light moves on geodesics through curved spacetime, it too is affected by the gravitational pull of a black hole or any other massive object. In fact, Einstein's prediction of the gravitational deflection of light by our sun was [confirmed in 1919](http://rsta.royalsocietypublishing.org/content/220/571-581/291), four years after he published his theory of general relativity, by Eddington and his team during a solar eclipse. This discovery, with a British research team confirming a German physicist's theory shortly after World War I, was remarkable on its own and provided a crucial precision test of general relativity.
 
 Today, gravitational lensing is widely used by astronomers to study distant objects. The way a massive cluster of galaxies lenses a background light source can often tell us about the cluster's structure. Since visible matter cannot account for a large amount of the gravitational lensing we observe, astronomers conclude that the remaining mass may be of some unknown type that only interacts gravitationally and is therefore called [_dark matter_](https://en.wikipedia.org/wiki/Dark_matter).
 
 ---
 
 In this simulation you can explore a variety of optical effects that occur when a massive object lenses a background light source. Move the device around or pan with your finger while keeping track of a background star that approaches the lens. In particular, you can try to find the following configurations that astronomers also observe with telescopes:
 
 - **Multiple images**:
 - **Einstein ring**:
 
*/
let source = /*#-editable-code*/#imageLiteral(resourceName: "lensed_background.jpg")/*#-end-editable-code*/
applyLens(to: source) // TODO
/*
 ---
 
 ### References:
 
 - The particular lens used in the simulation is modeled after the observation of the [RXJ1131-1231](https://www.cfa.harvard.edu/castles/Individual/RXJ1131.html) quadruply imaged quasar.
 - Discovery of RXJ1131-1231: [Sluse et al.](https://arxiv.org/pdf/astro-ph/0307345.pdf) (2003)
 https://arxiv.org/pdf/astro-ph/0307345.pdf
 - Lens displacement map: [gravlens](http://www.physics.rutgers.edu/~keeton/gravlens/) by Chuck Keeton et al., Rutgers university, New Jersey and [Malte Tewes](https://astro.uni-bonn.de/~mtewes/wiki/doku.php), Argelander-Institut für Astronomie, Bonn, Germany

 ---
 
 [Finally, explore how black holes merge and produce gravitational waves >>](@next).
*/
