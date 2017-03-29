//#-hidden-code
import UIKit
import PlaygroundSupport
let proxy = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy

func applyLens(to source: UIImage) {
    guard let imageData = UIImageJPEGRepresentation(source, 1) else { return }
    proxy?.send(.data(imageData))
}
//#-end-hidden-code
/*:
 ## 2  Gravitational lensing
 
 Since not only massive particles but also light moves on geodesics through curved spacetime, it too is affected by the gravitational pull of a black hole or any other massive object. In fact, Einstein's prediction of the gravitational deflection of light by our sun was [confirmed in 1919](http://rsta.royalsocietypublishing.org/content/220/571-581/291), four years after he published his theory of general relativity, by Eddington and his team during a solar eclipse. This discovery, with a British research team confirming a German physicist's theory shortly after World War I, was remarkable on its own and provided a crucial precision test of general relativity.
 
 Today, gravitational lensing is widely used by astronomers to study distant objects. The way a massive cluster of galaxies lenses a background light source can often tell us about the cluster's structure. Since visible matter cannot account for a large amount of the gravitational lensing we observe, astronomers conclude that the remaining mass may be of some unknown type that only interacts gravitationally and is therefore called [_dark matter_](https://en.wikipedia.org/wiki/Dark_matter).
 
 - callout(Explore): In this simulation you can explore a variety of optical effects that occur when a massive object lenses a background light source. Move the device around or pan with your finger while keeping track of a background star that approaches the lens. In particular, you can try to find the following configurations that astronomers also observe with telescopes:
 
    - **Multiple images**: The light from a single background star reaches the observer on multiple paths.
 
        ![Multiple images](multiple_images.jpg)
 
    - **Einstein ring**: If a background star is placed precisely behind a spherically symmetric source, its multiple images combine to a closed ring. Since the lens [RXJ1131-1231](https://www.cfa.harvard.edu/castles/Individual/RXJ1131.html) used in this simulation is slightly asymmetric, we see ring segments.
 
        ![Einstein ring](einstein_ring.jpg)
 
    You can select your own image as the lensed background source below.

*/
let source: UIImage = /*#-editable-code*/#imageLiteral(resourceName: "lensed_background.jpg")/*#-end-editable-code*/
applyLens(to: source)
/*:
 [Finally, explore how black holes merge and produce gravitational waves >>](@next)

 ## References:
 
 - The particular lens used in this simulation is modeled after the observation of the [RXJ1131-1231](https://www.cfa.harvard.edu/castles/Individual/RXJ1131.html) quadruply imaged quasar.
 - Discovery of RXJ1131-1231: [Sluse et al.](https://arxiv.org/pdf/astro-ph/0307345.pdf) (2003)
 - Lens displacement map: [gravlens](http://www.physics.rutgers.edu/~keeton/gravlens/) by Chuck Keeton et al., Rutgers university, New Jersey and [Malte Tewes](https://astro.uni-bonn.de/~mtewes/wiki/doku.php), Argelander-Institut für Astronomie, Bonn, Germany
*/
