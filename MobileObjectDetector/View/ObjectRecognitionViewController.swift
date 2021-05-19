//
//  ObjectRecognitionViewController.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 12/16/20.
//

import UIKit
import Foundation
import AVFoundation
import Vision
import RxSwift
import RxCocoa
import RxGesture

class ObjectRecognitionViewController: UIViewController, DetectionViewModelEvents {
    
    // MARK: - UI Properties
    private var rootLayer: CALayer! = nil
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private var detectionOverlay: CALayer! = nil
    private var blurView: UIView!
    @IBOutlet private weak var previewView: UIView!
    @IBOutlet private weak var actionButton: UIButton!
    @IBOutlet private weak var settingsMenuButton: UIButton!
    @IBOutlet private weak var selectedModelLabel: UILabel!
    @IBOutlet private weak var inferenceLabel: UILabel!
    @IBOutlet private weak var computeUnitSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var zoomFactorButton: UIButton!
    @IBOutlet private weak var iouLabel: UILabel!
    @IBOutlet private weak var iouStepper: UIStepper!
    @IBOutlet private weak var confidenceLabel: UILabel!
    @IBOutlet private weak var confidenceStepper: UIStepper!
    @IBOutlet private weak var detectionStackView: UIStackView!
    
    
    // MARK: - Properties
    private var detectionViewModel: DetectionViewModel!
    
    // MARK: - Reactive Properties
    private var disposeBag = DisposeBag()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

// MARK: - Setup
extension ObjectRecognitionViewController {
    static func instantiate(detectionViewModel: DetectionViewModel) -> ObjectRecognitionViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let viewController = storyboard.instantiateInitialViewController() as! ObjectRecognitionViewController
        viewController.detectionViewModel = detectionViewModel
        
        return viewController
    }
    
    private func setup() {
        checkForCameraAccess()
        setupAdditionalUIElements()
        detectionViewModel.configure(delegate: self)
        setupAVCapture()
        setupBindings()
    }
}

// MARK: - Vision
extension ObjectRecognitionViewController {
    func setupAVCapture() {
        detectionViewModel.prepareAVCapture()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: detectionViewModel.session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.insertSublayer(blurView.layer, below: rootLayer)
        
        rootLayer = previewView.layer
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
        
        rootLayer.insertSublayer(previewLayer, below: actionButton.layer)
        
        detectionViewModel.startCaptureSession()
    }
    
    func drawVisionRequestResults(_ observations: [VNRecognizedObjectObservation]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        guard detectionOverlay != nil else { return }
        
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        
        for observation in observations {
            // Select only the label with the highest confidence.
            guard let topLabel = observation.labels.first else {
                print("Object observation has no labels")
                continue
            }
            
            let objectBounds = VNImageRectForNormalizedRect(observation.boundingBox, Int(detectionViewModel.bufferSize.width), Int(detectionViewModel.bufferSize.height))
            
            let shapeLayer = createRoundedRectLayerWithBounds(objectBounds)
            
            let textLayer = createTextSubLayerInBounds(objectBounds,
                                                       identifier: topLabel.identifier,
                                                       confidence: topLabel.confidence)
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
        }
        
        updateLayerGeometry()
        
        CATransaction.commit()
    }
}

// MARK: - UI Setup
extension ObjectRecognitionViewController {
    private func setupAdditionalUIElements() {
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = .black
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.systemChromeMaterialDark)
        blurView = UIVisualEffectView(effect: blurEffect)
        
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        zoomFactorButton.layer.masksToBounds = true
        zoomFactorButton.layer.cornerRadius = zoomFactorButton.frame.size.width / 2
    }
    
    private func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: detectionViewModel.bufferSize.width,
                                         height: detectionViewModel.bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    private func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / detectionViewModel.bufferSize.height
        let yScale: CGFloat = bounds.size.height / detectionViewModel.bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
    }
    
    private func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        
        let confidenceFormatted = String(format: ": %.1f", confidence * 100)
        textLayer.fontSize = 21
        textLayer.string = "\(identifier)\(confidenceFormatted)"
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor.SystemItem.white
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        
        return textLayer
    }
    
    private func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.8, 1.0, 0.6])
        shapeLayer.borderWidth = 2.0
        shapeLayer.cornerRadius = 14
        return shapeLayer
    }
}

// MARK: - Binding
extension ObjectRecognitionViewController {
    func setupBindings() {
        view.rx.tapGesture() { gesture, _ in
            gesture.numberOfTapsRequired = 3
        }
        .when(.recognized)
        .subscribe(onNext: { [weak self] _ in
            self?.detectionViewModel.switchCamera()
            self?.zoomFactorButton.isEnabled.toggle()
            self?.zoomFactorButton.isEnabled == false ? ( self?.zoomFactorButton.alpha = 0.5) :  (self?.zoomFactorButton.alpha = 1.0)
        })
        .disposed(by: disposeBag)
        
        actionButton.rx.tap
            .bind { [unowned self] _ in
                self.actionButton.isSelected.toggle()
                
                let isSelected = self.actionButton.isSelected
                
                if isSelected {
                    self.actionButton.tintColor = .clear
                    self.actionButton.setTitleColor(.black, for: .selected)
                    self.actionButton.rx.title(for: .selected).onNext("Stop Detecting")
                    self.actionButton.backgroundColor = UIColor.Button.stop
                    self.detectionViewModel.setDetectionState(to: .active)
                    self.computeUnitSegmentedControl.isEnabled.toggle()
                } else {
                    self.actionButton.rx.title(for: .normal).onNext("Start Detecting")
                    self.actionButton.backgroundColor = UIColor.Button.start
                    self.detectionViewModel.setDetectionState(to: .inactive)
                    self.computeUnitSegmentedControl.isEnabled.toggle()
                }
                
            }.disposed(by: disposeBag)
        
        settingsMenuButton.rx.tap
            .bind { [unowned self] _ in
                // TODO: stop detection if present
                self.detectionViewModel.stopCaptureSession()
                
                let settingsVC = SettingsViewController()
                settingsVC.prepare(detectionViewModel: detectionViewModel)
                self.navigationController?.pushViewController(settingsVC, animated: true)
                
                settingsVC.rx.deallocating.bind { _ in
                    self.detectionViewModel.startCaptureSession()
                }.disposed(by: self.disposeBag)
                
            }.disposed(by: disposeBag)
        
        computeUnitSegmentedControl.rx
            .selectedSegmentIndex
            .skip(1)
            .bind(onNext: { [unowned self] index in
                let computeUnit = ComputeUnit(rawValue: index) ?? .ane
                self.detectionViewModel.setComputeUnit(to: computeUnit)
            }).disposed(by: disposeBag)
        
        zoomFactorButton.rx.tap
            .bind(onNext: { [unowned self] _ in
                self.detectionViewModel.changeZoomFactor()
            }).disposed(by: disposeBag)
        
        detectionViewModel.currentZoomFactorText
            .drive(zoomFactorButton.rx.title())
            .disposed(by: disposeBag)
        
        // TODO: make only available after model is loaded
        iouStepper.rx.value
            .skip(1)
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [unowned self] value in
                self.detectionViewModel.setIouThreshold(to: value.round(places: 2))
                self.iouLabel.rx.text.onNext("IoU: \(value.round(places: 2))")
            }).disposed(by: disposeBag)
        
        // TODO: make only available after model is loaded
        confidenceStepper.rx.value
            .skip(1)
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [unowned self] value in
                self.detectionViewModel.setConfidenceThreshold(to: value.round(places: 2))
                self.confidenceLabel.rx.text.onNext("Confidence: \(value.round(places: 2))")
            }).disposed(by: disposeBag)
        
        detectionViewModel.detectionStateDriver
            .distinctUntilChanged()
            .drive(onNext: { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .active:
                    self.setupLayers()
                    self.updateLayerGeometry()
                    UIView.transition(with: self.detectionStackView, duration: 0.4,
                                      options: .transitionCrossDissolve,
                                      animations: {
                                        self.detectionStackView.isHidden.toggle()
                                      })
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.detectionViewModel.setupVision()
                    }
                case .inactive:
                    UIView.transition(with: self.detectionStackView, duration: 0.4,
                                      options: .transitionCrossDissolve,
                                      animations: {
                                        self.detectionStackView.isHidden.toggle()
                                      })
                    self.detectionViewModel.cleanup()
                    if self.detectionOverlay != nil {
                        self.detectionOverlay.removeFromSuperlayer()
                    }
                }
            }).disposed(by: disposeBag)
        
        detectionViewModel.inferenceTimeDriver
            .drive(inferenceLabel.rx.text)
            .disposed(by: disposeBag)
        
        detectionViewModel.model.selectedModelDriver
            .map({ $0.name })
            .drive(selectedModelLabel.rx.text)
            .disposed(by: disposeBag)
    }
}

//MARK: - Private methods
extension ObjectRecognitionViewController {
    private func checkForCameraAccess() {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            return
        } else {
            presentCameraAccessAlert()
        }
    }
    
    private func presentCameraAccessAlert() {
        let alert = UIAlertController(title: "Oops", message: "To continue, yo'll need to allow camera access in settings", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open", style: .default, handler: { action in
                                        switch action.style{
                                        case .default:
                                            UIApplication.shared.open(NSURL(string:UIApplication.openSettingsURLString)! as URL, options: [:], completionHandler: nil)
                                        default:
                                            break
                                        }}))
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK: - Device orientation setup
extension ObjectRecognitionViewController {
    // TODO: Allow multi orientation
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}

//MARK: - AVCaptureDelegate
extension ObjectRecognitionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        switch detectionViewModel.detectionState {
        case .active:
            self.detectionViewModel.predictWithPixelBuffer(sampleBuffer: sampleBuffer)
        case .inactive:
            break
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {}
}
