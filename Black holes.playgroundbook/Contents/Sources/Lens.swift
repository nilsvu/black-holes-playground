/*
 Lens.swift
 
 Author: [Nils Leif Fischer](http://nilsleiffischer.de/)
*/

import UIKit
import CoreImage


private let linearColorSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!


/// Applies displacement map to an image that models the gravitational lensing effect the [RXJ1131-1231](https://www.cfa.harvard.edu/castles/Individual/RXJ1131.html) quasar has on a background light source.
public class Lens {
    
    private let kernel: CIKernel = CIKernel(string: try! String(contentsOf: #fileLiteral(resourceName: "displacement.cikernel")))!
    private let xDisplacement: CIImage = CIImage(image: #imageLiteral(resourceName: "xsrc.png"), options: [ kCIImageColorSpace: linearColorSpace ])!
    private let yDisplacement: CIImage = CIImage(image: #imageLiteral(resourceName: "ysrc.png"), options: [ kCIImageColorSpace: linearColorSpace ])!
    
    public init() {}
    
    public func appliedTo(_ source: CIImage, scaledToFill fill: CGRect) -> CIImage {
        let viewportScale: CGFloat = min(xDisplacement.extent.width / fill.width, xDisplacement.extent.height / fill.height)
        let viewport = CGRect(origin: fill.origin, size: fill.size.applying(CGAffineTransform(scaleX: viewportScale, y: viewportScale)))
        let translation = CIVector(cgPoint: viewport.origin)
        let lensShift = CIVector(x: (xDisplacement.extent.size.width - viewport.size.width) / 2, y: (xDisplacement.extent.size.height - viewport.size.height) / 2)
        let roi = viewport.insetBy(dx: -lensShift.x, dy: -lensShift.y)
        let lensedImage = kernel.apply(
            withExtent: viewport,
            roiCallback: { _, _ in .infinite },
            arguments: [
                CISampler(image: source.cropping(to: roi)),
                CISampler(image: xDisplacement),
                CISampler(image: yDisplacement),
                translation,
                lensShift
            ])!
        return lensedImage.applying(CGAffineTransform(translationX: -lensedImage.extent.origin.x, y: -lensedImage.extent.origin.y)).applying(CGAffineTransform(scaleX: 1/viewportScale, y: 1/viewportScale))
    }
    
    
}
