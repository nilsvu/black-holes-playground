/*
 LensingViewController.swift
 
 Author: [Nils Leif Fischer](http://nilsleiffischer.de/)
*/

import PlaygroundSupport
import UIKit
import CoreImage
//import AVFoundation
import CoreMotion
import GLKit


/// Applies a lensing effect to an image that models the gravitational lensing effect the [RXJ1131-1231](https://www.cfa.harvard.edu/castles/Individual/RXJ1131.html) quasar has on a background light source.
public class LensingViewController: UIViewController, UIGestureRecognizerDelegate/*, AVCaptureVideoDataOutputSampleBufferDelegate*/ {
    
    // MARK: Interface elements
    
    private let lensedImageView = UIImageView(frame: .zero)
    private let motionControlButton = UIButton(frame: .zero)
    
    
    // MARK: Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup view hierarchy
        view.addSubview(lensedImageView)
        lensedImageView.backgroundColor = .black
        
        view.addSubview(motionControlButton)
        motionControlButton.setImage(#imageLiteral(resourceName: "compass_icon.png"), for: .normal)
        motionControlButton.addTarget(self, action: #selector(motionControlButtonPressed(sender:)), for: .touchUpInside)
        
        // Setup gesture recognizers
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(gestureRecognizer:)))
        panGestureRecognizer.delegate = self
        self.panGestureRecognizer = panGestureRecognizer
        view.addGestureRecognizer(panGestureRecognizer)
        
        interactionMode = .motion
        
        render()
        
        // initializeCameraCapture()
    }
    
    
    // MARK: Lensing
    
    public var source = CIImage(image: #imageLiteral(resourceName: "milkyway.jpg"))! {
        didSet {
            render()
        }
    }
    public let lens = Lens()
    public var viewportTranslation: CGPoint = .zero {
        didSet {
            render()
        }
    }
    public var viewport: CGRect {
        return CGRect(origin: viewportTranslation, size: lensedImageView.frame.size)
    }
    
    private func render() {
        lensedImageView.image = UIImage(ciImage: lens.appliedTo(source, scaledToFill: viewport))
    }
    
    
    // MARK: User Interaction
    
    public enum InteractionMode {
        case touch, motion
    }
    
    public var interactionMode: InteractionMode = .touch {
        didSet {
            switch interactionMode {
            case .touch:
                motionManager.stopDeviceMotionUpdates()
                motionControlButton.isHidden = false
            case .motion:
                motionManager.deviceMotionUpdateInterval = 1 / 30 // 30Hz refresh rate
                motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: OperationQueue.main, withHandler: { motion, error in
                    guard let attitude = motion?.attitude else { return }
                    let rotationMatrix = attitude.rotationMatrix
                    let orientationRotation = Float(atan2(-rotationMatrix.m13, sqrt(pow(rotationMatrix.m23, 2) + pow(rotationMatrix.m33, 2))))
                    let effectiveRotationMatrix = GLKMatrix3Multiply(GLKMatrix3(m: (Float(rotationMatrix.m11), Float(rotationMatrix.m12), Float(rotationMatrix.m13), Float(rotationMatrix.m21), Float(rotationMatrix.m22), Float(rotationMatrix.m23), Float(rotationMatrix.m31), Float(rotationMatrix.m32), Float(rotationMatrix.m33))), GLKMatrix3MakeZRotation(orientationRotation))
                    let azimuth = atan2(effectiveRotationMatrix.m01, effectiveRotationMatrix.m00)
                    let pitch = atan2(effectiveRotationMatrix.m12, effectiveRotationMatrix.m22)
                    self.viewportTranslation = CGPoint(x: CGFloat((-azimuth + .pi) / (2 * .pi)) * self.source.extent.width , y: CGFloat(pitch / .pi) * self.source.extent.height)
                })
                motionControlButton.isHidden = true
            }
        }
    }
    
    func motionControlButtonPressed(sender: UIButton) {
        self.interactionMode = .motion
    }
    
    // MARK: Motion
    
    private let motionManager = CMMotionManager()
    
    
    // MARK: Gestures
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var viewportTranslationBeforePan: CGPoint = .zero
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewportTranslationBeforePan = viewportTranslation
        interactionMode = .touch
        return true
    }
    
    public func pan(gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: view)
        self.viewportTranslation = CGPoint(x: viewportTranslationBeforePan.x - translation.x, y: viewportTranslationBeforePan.y + translation.y)
    }
    
    
    // MARK: Camera capture
    
    //    private let captureSession = AVCaptureSession()
    //    private let videoOutputQueue = DispatchQueue(label: "video output")
    //    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    //
    //    private func initializeCameraCapture() {
    //        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
    //
    //        let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    //
    //        let input = try! AVCaptureDeviceInput(device: camera)
    //        captureSession.addInput(input)
    //
    //        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)!
    //        self.cameraPreviewLayer = previewLayer
    //        previewLayer.frame = view.bounds
    //        view.layer.addSublayer(previewLayer)
    //
    //        let videoOutput = AVCaptureVideoDataOutput()
    //        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
    //        captureSession.addOutput(videoOutput)
    //
    //        captureSession.startRunning()
    //    }
    //
    //    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
    //        print("camera captured!")
    //    }
    
    
    // MARK: Layout
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        lensedImageView.frame = view.bounds
        
        let motionControlButtonSize = motionControlButton.intrinsicContentSize
        motionControlButton.frame = CGRect(origin: CGPoint(x: view.bounds.size.width - motionControlButtonSize.width - 20, y: view.bounds.size.height / 2 - motionControlButtonSize.height / 2), size: motionControlButtonSize)
        
        render()
    }
    
}


// MARK: Playground communication

extension LensingViewController: PlaygroundLiveViewMessageHandler {
    
    public func receive(_ message: PlaygroundValue) {
        switch message {
        case .data(let imageData):
            guard let source = CIImage(data: imageData) else { return }
            self.source = source
        default:
            return
        }
    }
}
