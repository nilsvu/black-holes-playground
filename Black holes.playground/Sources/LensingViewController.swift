import UIKit
import CoreImage
import AVFoundation
import CoreMotion


let lens = Lens()

let source = CIImage(image: #imageLiteral(resourceName: "milkyway.jpg"))!
let viewport = CGRect(x: 1000, y: 1000, width: 2000, height: 2000)
let lensedImage = lens.appliedTo(source, scaledToFill: viewport)


public class LensingViewController: UIViewController, UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
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
    public var source = CIImage(image: #imageLiteral(resourceName: "milkyway.jpg"))!
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
                motionManager.deviceMotionUpdateInterval = 0.015
                motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: OperationQueue.main, withHandler: { motion, error in
                    guard let attitude = motion?.attitude else { return }
                    let horizontalShift = CGFloat((-attitude.roll + .pi) / (2 * .pi) / 2)
                    let verticalShift = CGFloat(attitude.pitch / .pi)
                    self.viewportTranslation = CGPoint(x: horizontalShift * self.source.extent.width , y: verticalShift * self.source.extent.height)
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
        viewportTranslation = CGPoint(x: viewportTranslationBeforePan.x - translation.x, y: viewportTranslationBeforePan.y + translation.y)
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
    //        guard let filter = Filters[FilterNames[filtersControl.selectedSegmentIndex]] else
    //        {
    //            return
    //        }
    //
    //        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    //        let cameraImage = CIImage(CVPixelBuffer: pixelBuffer!)
    //
    //        filter!.setValue(cameraImage, forKey: kCIInputImageKey)
    //
    //        let filteredImage = UIImage(CIImage: filter!.valueForKey(kCIOutputImageKey) as! CIImage!)
    //
    //        dispatch_async(dispatch_get_main_queue())
    //        {
    //            self.imageView.image = filteredImage
    //        }
    //        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    //        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)
    //
    //        let outputImage = UIImage(ciImage: cameraImage)
    //
    //        DispatchQueue.main.async {
    //            self.frameImageView.image = outputImage
    //            self.debugLabel.text = "async captured!"
    //
    //        }
    //
    //    }
    
    
    // MARK: Layout
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        lensedImageView.frame = view.bounds
        
        let motionControlButtonSize = motionControlButton.intrinsicContentSize
        motionControlButton.frame = CGRect(origin: CGPoint(x: view.bounds.size.width - motionControlButtonSize.width - 20, y: view.bounds.size.height / 2 - motionControlButtonSize.height / 2), size: motionControlButtonSize)
        
        render()
        // cameraPreviewLayer?.frame = view.bounds
    }
    
}
