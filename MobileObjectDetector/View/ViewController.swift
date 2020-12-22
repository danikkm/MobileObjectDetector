//
//  ViewController.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 12/16/20.
//

import UIKit
import AVFoundation
import Vision
import RxSwift
import RxCocoa
import RxGesture

class ViewController: UIViewController, DetectionViewModelEvents {
    // TODO: think of other way of doing this
    var detectionViewModel: DetectionViewModelProtocol!
    var mlModelsViewModel: MLModelsViewModelProtocol!
    private var settingsViewModel: SettingsViewModelProtocol!
    
    var rootLayer: CALayer! = nil
    
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private var blurView: UIView!
    @IBOutlet weak private var previewView: UIView!
    @IBOutlet weak private var actionButton: UIButton! {
        didSet {
            // TODO: refactor this
            actionButton.setTitle("Start Detecting", for: .normal)
            actionButton.layer.cornerRadius = 32
            actionButton.clipsToBounds = true
            actionButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
            actionButton.setTitleColor(.black, for: .normal)
            actionButton.backgroundColor = UIColor.Button.start
        }
    }
    @IBOutlet weak private var settingsMenuButton: UIButton! {
        didSet {
            settingsMenuButton.tintColor = .white
        }
    }
    @IBOutlet weak var selectedModelLabel: UILabel! {
        didSet {
            selectedModelLabel.textColor = .white
        }
    }
    
    private var disposeBag = DisposeBag()
    
    static func instantiate(detectionViewModel: DetectionViewModelProtocol, mlModelsViewModel: MLModelsViewModelProtocol, settingsViewModel: SettingsViewModelProtocol) -> ViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let viewController = storyboard.instantiateInitialViewController() as! ViewController
        viewController.detectionViewModel = detectionViewModel
        viewController.mlModelsViewModel = mlModelsViewModel
        viewController.settingsViewModel = settingsViewModel
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkForCameraAccess()
        detectionViewModel.configure(delegate: self)
        setupAdditionalUIElements()
        setupAVCapture()
        setupParentBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupAdditionalUIElements() {
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = .black
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.systemChromeMaterialDark)
        blurView = UIVisualEffectView(effect: blurEffect)
        
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func setupParentBindings() {
        view.rx.tapGesture() { gesture, _ in
            gesture.numberOfTapsRequired = 2
        }
        .when(.recognized)
        .subscribe(onNext: { [weak self] _ in
            self?.detectionViewModel.switchCamera()
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
                    
                    self.detectionViewModel.detectionStateRelay.accept(.active)
                } else {
                    self.actionButton.rx.title(for: .normal).onNext("Start Detecting")
                    self.actionButton.backgroundColor = UIColor.Button.start
                    self.detectionViewModel.detectionStateRelay.accept(.inactive)
                }
                
            }.disposed(by: disposeBag)
        
        settingsMenuButton.rx.tap
            .bind { [unowned self] _ in
                let settingsVC = SettingsViewController()
                
                settingsVC.prepare(detectionViewModel: detectionViewModel, mlModelsViewModel: mlModelsViewModel, settingsViewModel: settingsViewModel)
                self.navigationController?.pushViewController(settingsVC, animated: true)
                
                // TODO: stop detection if present
                self.detectionViewModel.stopCaptureSession()
                
                settingsVC.rx.deallocating.bind { _ in
                    self.detectionViewModel.startCaptureSession()
                    
                }.disposed(by: self.disposeBag)
                
            }.disposed(by: disposeBag)
        
        detectionViewModel.cameraTypeObservable
            .subscribe(onNext: { [weak self] type in
                switch type {
                case .backFacing:
                    self?.settingsViewModel.frameRateSwitchRelay.accept(.smooth)
                    self?.settingsViewModel.isFrameRateToggleEnabledRelay.accept(true)
                case .frontFacing:
                    self?.settingsViewModel.frameRateSwitchRelay.accept(.normal)
                    self?.settingsViewModel.isFrameRateToggleEnabledRelay.accept(false)
                }
            }).disposed(by: disposeBag)
    }
    
    
    func setupAVCapture() {
        detectionViewModel.prepareAVCapture()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: detectionViewModel.session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.insertSublayer(blurView.layer, below: rootLayer)
        
        rootLayer = previewView.layer
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
        
        rootLayer.insertSublayer(previewLayer, below: actionButton.layer)
    }
}

//MARK: - Private methods
extension ViewController {
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
extension ViewController {
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
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // in subclass
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //        print("Frame dropped")
    }
}
