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
    var viewModel: DetectionViewModelProtocol!
    var rootLayer: CALayer! = nil
    
    private var disposeBag = DisposeBag()
    
    @IBOutlet weak private var previewView: UIView!
    @IBOutlet weak private var actionButton: UIButton! {
        didSet {
            // TODO: refactor this
            actionButton.setTitle("Start Detecting", for: .normal)
            actionButton.layer.cornerRadius = 32
            actionButton.clipsToBounds = true
            actionButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
            actionButton.setTitleColor(.black, for: .normal)
            actionButton.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        }
    }
    
    @IBOutlet weak private var settingsMenuButton: UIButton!
    
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil

    static func instantiate(viewModel: DetectionViewModelProtocol) -> ViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let viewController = storyboard.instantiateInitialViewController() as! ViewController
        viewController.viewModel = viewModel
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.configure(delegate: self)
        navigationController?.navigationBar.isHidden = true

        setupAVCapture()
        setupBindings()
    }
    
    
    func setupBindings() {
        actionButton.rx.tap
            .bind { [unowned self] _ in
                self.actionButton.isSelected.toggle()
                
                let isSelected = self.actionButton.isSelected
                
                if isSelected {
                    self.actionButton.tintColor = .clear
                    self.actionButton.setTitleColor(.black, for: .selected)
                    self.actionButton.rx.title(for: .selected).onNext("Stop Detecting")
                    self.actionButton.backgroundColor = UIColor.Button.stop
                    
                    self.viewModel.detectionState.accept(.active)
                } else {
                    self.actionButton.rx.title(for: .normal).onNext("Start Detecting")
                    self.actionButton.backgroundColor = UIColor.Button.start
                    self.viewModel.detectionState.accept(.inactive)
                }
                
            }.disposed(by: disposeBag)
        
        settingsMenuButton.rx.tap
            .bind { [unowned self] _ in
                let settingsVC = SettingsViewController()
                present(settingsVC, animated: true, completion: nil)

                self.viewModel.stopCaptureSession()
                
                settingsVC.rx.deallocated.bind { _ in
                    self.viewModel.startCaptureSession()
                    
                }.disposed(by: self.disposeBag)
                
            }.disposed(by: disposeBag)
        
        view.rx.longPressGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.switchCamera()
            }).disposed(by: disposeBag)
    }
    
    func setupAVCapture() {
        viewModel.prepareAVCapture()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: viewModel.session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        rootLayer = previewView.layer
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
        rootLayer.insertSublayer(previewLayer, below: actionButton.layer)
    }
}

//MARK: - Setup
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


extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // in subclass
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            print("Frame dropped")
    }
}
