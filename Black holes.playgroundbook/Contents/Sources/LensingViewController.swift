/*
 LensingViewController.swift

 Author: [Nils Leif Fischer](http://nilsleiffischer.de/)
*/

import PlaygroundSupport
import UIKit
import CoreImage
import AVFoundation
import CoreMotion
import GLKit

/// A suitable image to demonstrate lensing
private let defaultSourceImage = CIImage(image: #imageLiteral(resourceName: "milkyway.jpg"))!


/// Applies a lensing effect to an image that models the gravitational lensing effect the [RXJ1131-1231](https://www.cfa.harvard.edu/castles/Individual/RXJ1131.html) quasar has on a background light source.
public class LensingViewController: UIViewController, UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    // MARK: Source mode

    /// The sources available for lensing
    public enum SourceMode {
        case image(CIImage), camera
    }

    /// The source that is selected for demonstrating the lensing effect
    public var sourceMode: SourceMode = .image(defaultSourceImage) {
        didSet {
            self.configureView(for: sourceMode)
        }
    }

    // MARK: Interface elements

    private lazy var lensedImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .black
        return imageView
    }()
    private lazy var motionControlButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(#imageLiteral(resourceName: "compass_icon.png"), for: .normal)
        return button
    }()
    private lazy var cameraModeButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(#imageLiteral(resourceName: "camera_icon@2x.png"), for: .normal)
        return button
    }()
    private lazy var rotateCameraButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(#imageLiteral(resourceName: "rotate_icon@2x.png"), for: .normal)
        return button
    }()
    private lazy var controlsStackview: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            self.cameraModeButton,
            self.rotateCameraButton,
            self.motionControlButton
            ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()
    
    // MARK: Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Setup view hierarchy
        view.addSubview(lensedImageView)
        view.addSubview(controlsStackview)
        
        // Layout
        let margins = view.layoutMarginsGuide
        lensedImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        lensedImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        lensedImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        lensedImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        controlsStackview.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
        controlsStackview.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
        
        // Setup user interaction targets
        motionControlButton.addTarget(self, action: #selector(motionControlButtonPressed(sender:)), for: .touchUpInside)
        cameraModeButton.addTarget(self, action: #selector(cameraModeButtonPressed(sender:)), for: .touchUpInside)
        rotateCameraButton.addTarget(self, action: #selector(rotateCameraButtonPressed(sender:)), for: .touchUpInside)
        
        // Setup gesture recognizers
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(gestureRecognizer:)))
        panGestureRecognizer.delegate = self
        self.panGestureRecognizer = panGestureRecognizer
        view.addGestureRecognizer(panGestureRecognizer)

        configureView(for: sourceMode)
    }

    /// Adapts the view to the selected source mode
    private func configureView(for sourceMode: SourceMode) {
        switch sourceMode {
        case .image(let sourceImage):
            captureSession.stopRunning()
            interactionMode = .motion
            self.rotateCameraButton.isHidden = true
            cameraModeButton.setImage(#imageLiteral(resourceName: "camera_icon@2x.png"), for: .normal)
            render(sourceImage, translatedBy: viewportTranslation)
        case .camera:
            initializeCameraCapture()
            interactionMode = .none
            self.rotateCameraButton.isHidden = false
            cameraModeButton.setImage(#imageLiteral(resourceName: "close_icon@2x.png"), for: .normal)
            captureSession.startRunning()
        }

    }

    // MARK: Lensing

    /// The lens model providing the physics and image distortion logic
    public let lens = Lens()

    /// Specifies the part of the source images that is visible on screen
    private var viewportTranslation: CGPoint = .zero

    /// Distorts and displays the source image on screen
    private func render(_ sourceImage: CIImage, translatedBy viewportTranslation: CGPoint? = nil) {
        let translation = viewportTranslation ?? CGPoint(x: (sourceImage.extent.size.width - lensedImageView.frame.size.width) / 2, y: (sourceImage.extent.size.height - lensedImageView.frame.size.height) / 2)
        let viewport = CGRect(origin: translation, size: lensedImageView.frame.size)
        let lensedImage = lens.appliedTo(sourceImage, scaledToFill: viewport)
        DispatchQueue.main.async {
            self.lensedImageView.image = UIImage(ciImage: lensedImage)
        }
    }


    // MARK: User Interaction

    public enum InteractionMode {
        case none, touch, motion
    }

    public var interactionMode: InteractionMode = .none {
        didSet {
            switch interactionMode {
            case .none:
                motionManager.stopDeviceMotionUpdates()
                self.motionControlButton.isHidden = true
                panGestureRecognizer.isEnabled = false
            case .touch:
                motionManager.stopDeviceMotionUpdates()
                self.motionControlButton.isHidden = false
                panGestureRecognizer.isEnabled = true
            case .motion:
                motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: OperationQueue.main, withHandler: self.handleMotionUpdate)
                self.motionControlButton.isHidden = true
                panGestureRecognizer.isEnabled = true
            }
        }
    }

    func cameraModeButtonPressed(sender: UIButton) {
        switch sourceMode {
        case .image:
            self.sourceMode = .camera
            presentOrientationSelection()
        case .camera:
            self.sourceMode = .image(defaultSourceImage)
        }
    }
    
    func rotateCameraButtonPressed(sender: UIButton) {
        presentOrientationSelection()
    }
    
    private func presentOrientationSelection() {
        let alert = UIAlertController(title: "Select orientation", message: "Playgrounds are unable to access the orientation of your device. Please select how you are currently holding your iPad. Then consider filing a feature request at https://bugreport.apple.com.", preferredStyle: .actionSheet)
        func selectCameraOrientationHandler(_ orientation: AVCaptureVideoOrientation) -> ((UIAlertAction) -> ()) {
            return { action in
                self.selectCameraOrientation(orientation)
            }
        }
        alert.addAction(UIAlertAction(title: "Landscape left", style: .default, handler: selectCameraOrientationHandler(.landscapeLeft)))
        alert.addAction(UIAlertAction(title: "Portrait", style: .default, handler: selectCameraOrientationHandler(.portrait)))
        alert.addAction(UIAlertAction(title: "Landscape right", style: .default, handler: selectCameraOrientationHandler(.landscapeRight)))
        alert.addAction(UIAlertAction(title: "Upside down", style: .default, handler: selectCameraOrientationHandler(.portraitUpsideDown)))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.sourceView = self.rotateCameraButton
        alert.popoverPresentationController?.sourceRect = self.rotateCameraButton.bounds
        self.present(alert, animated: true, completion: nil)
    }
    
    func selectCameraOrientation(_ orientation: AVCaptureVideoOrientation) {
        guard let videoConnection = videoOutput.connection(withMediaType: AVMediaTypeVideo) else { return }
        videoConnection.videoOrientation = orientation
    }
    
    func motionControlButtonPressed(sender: UIButton) {
        self.interactionMode = .motion
    }


    // MARK: Motion

    private let motionManager: CMMotionManager = {
        let motionManager = CMMotionManager()
        motionManager.deviceMotionUpdateInterval = 1 / 30 // 30Hz refresh rate
        return motionManager
    }()

    private func handleMotionUpdate(motion: CMDeviceMotion?, error: Error?) {
        guard case .image(let sourceImage) = self.sourceMode else { return }
        guard let attitude = motion?.attitude else { return }
        let rotationMatrix = attitude.rotationMatrix
        let orientationRotation = Float(atan2(-rotationMatrix.m13, sqrt(pow(rotationMatrix.m23, 2) + pow(rotationMatrix.m33, 2))))
        let effectiveRotationMatrix = GLKMatrix3Multiply(GLKMatrix3(m: (Float(rotationMatrix.m11), Float(rotationMatrix.m12), Float(rotationMatrix.m13), Float(rotationMatrix.m21), Float(rotationMatrix.m22), Float(rotationMatrix.m23), Float(rotationMatrix.m31), Float(rotationMatrix.m32), Float(rotationMatrix.m33))), GLKMatrix3MakeZRotation(orientationRotation))
        let azimuth = atan2(effectiveRotationMatrix.m01, effectiveRotationMatrix.m00)
        let pitch = atan2(effectiveRotationMatrix.m12, effectiveRotationMatrix.m22)
        let viewportTranslation = CGPoint(x: CGFloat((-azimuth + .pi) / (2 * .pi)) * (sourceImage.extent.width - 2*self.lensedImageView.bounds.size.width) , y: CGFloat(pitch / .pi) * sourceImage.extent.height)
        self.viewportTranslation = viewportTranslation
        self.render(sourceImage, translatedBy: viewportTranslation)
    }


    // MARK: Gestures

    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var viewportTranslationBeforePan: CGPoint = .zero

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        self.viewportTranslationBeforePan = viewportTranslation
        interactionMode = .touch
        return true
    }

    public func pan(gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: view)
        if case .image(let sourceImage) = sourceMode {
            self.viewportTranslation = CGPoint(x: viewportTranslationBeforePan.x - translation.x, y: viewportTranslationBeforePan.y + translation.y)
            render(sourceImage, translatedBy: viewportTranslation)
        }
    }


    // MARK: Camera capture

    private lazy var captureSession: AVCaptureSession = AVCaptureSession()
    private lazy var videoOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
    private lazy var videoOutputQueue: DispatchQueue = DispatchQueue(label: "video output")
    private var hasInitializedCameraCapture: Bool = false

    private func initializeCameraCapture() {
        guard !hasInitializedCameraCapture else { return }

        captureSession.sessionPreset = AVCaptureSessionPresetPhoto

        let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)

        let input = try! AVCaptureDeviceInput(device: camera)
        captureSession.addInput(input)
        
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        captureSession.addOutput(videoOutput)

        hasInitializedCameraCapture = true
    }

    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer)
        let fill = self.lensedImageView.bounds.size
        let scale: CGFloat = max(fill.width / cameraImage.extent.width, fill.height / cameraImage.extent.height)
        render(cameraImage.applying(CGAffineTransform(scaleX: scale, y: scale)))
    }


    // MARK: Layout

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if case .image(let sourceImage) = sourceMode {
            render(sourceImage, translatedBy: viewportTranslation)
        }

    }

}


// MARK: Playground communication

extension LensingViewController: PlaygroundLiveViewMessageHandler {

    public func receive(_ message: PlaygroundValue) {
        switch message {
        case .data(let imageData):
            guard let sourceImage = CIImage(data: imageData) else { return }
            self.sourceMode = .image(sourceImage)
        default:
            return
        }
    }
}
