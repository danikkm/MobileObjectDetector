//
//  DetectionViewModel.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-16.
//

import Foundation
import RxSwift
import RxCocoa
import AVFoundation
import Vision

protocol DetectionViewModelEvents: AnyObject {}

final class DetectionViewModel: DetectionViewModelProtocol {
    private weak var delegate: DetectionViewModelEvents?
    
    private let cameraTypeRelay = BehaviorRelay<CameraType>(value: .backFacing)
    private (set) var detectionStateRelay = PublishRelay<DetectionState>()
    private let coreMLModel = PublishSubject<VNCoreMLModel>()
    
    private (set) var videoDeviceRelay = BehaviorRelay<AVCaptureDevice?>(value: AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first)
    
    private (set) var session = AVCaptureSession()
    private (set) var bufferSize: CGSize = .zero
    private (set) var deviceInput: AVCaptureDeviceInput!
    private (set) var frameRateRelay = PublishRelay<Double>()
    private let capturePreset: AVCaptureSession.Preset?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    
    var cameraType: CameraType {
        return cameraTypeRelay.value
    }
    
    var videoDevice: AVCaptureDevice {
        // TODO: change this
        return videoDeviceRelay.value!
    }
    
    var detectionStateDriver: Driver<DetectionState> {
        return detectionStateRelay.asDriver(onErrorJustReturn: .inactive)
    }
    
    var frameRateObservable: Observable<Double> {
        return frameRateRelay.asObservable().debug()
    }
    
    var cameraTypeObservable: Observable<CameraType> {
        return cameraTypeRelay.asObservable()
    }
    
    init() {
        self.capturePreset = .vga640x480
    }
    
    func configure(delegate: DetectionViewModelEvents) {
        self.delegate = delegate
    }
}

// MARK: - Public methods
extension DetectionViewModel {
    func prepareAVCapture() {
        do {
            // remove force unwrap
            self.deviceInput = try AVCaptureDeviceInput(device: videoDevice)
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        
        session.beginConfiguration()
        session.sessionPreset = capturePreset ?? .vga640x480 // Model image size is smaller.
        
        guard session.canAddInput(self.deviceInput) else {
            print("Could not add video device input to the session")
            session.commitConfiguration()
            return
        }
        
        session.addInput(deviceInput)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            // Add a video data output
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(delegate as? ViewController, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        
        let captureConnection = videoDataOutput.connection(with: .video)
        
        // Always process the frames
        captureConnection?.isEnabled = true
        do {
            videoDevice.set(frameRate: 60.0)
            try videoDevice.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice.activeFormat.formatDescription))
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            
            videoDevice.unlockForConfiguration()
        } catch {
            print(error)
        }
        
        session.commitConfiguration()
    }
    
    func switchCamera() {
        switch cameraType {
        case .frontFacing:
            cameraTypeRelay.accept(.backFacing)
            addVideoInput(position: .back)
            videoDevice.set(frameRate: 60.0)
        case .backFacing:
            cameraTypeRelay.accept(.frontFacing)
            addVideoInput(position: .front)
            videoDevice.set(frameRate: 30.0)
        }
        
        //configure your session here
        DispatchQueue.main.async { [unowned self] in
            self.session.beginConfiguration()
            if self.session.canAddOutput(self.videoDataOutput) {
                self.session.addOutput(self.videoDataOutput)
            }
            self.session.commitConfiguration()
        }
    }
    
    func changeFrameRate(to frameRate: Double) {
        switch cameraType {
        case .frontFacing:
            break
        case .backFacing:
            videoDevice.set(frameRate: frameRate)
        }
    }
    
    func startCaptureSession() {
        session.startRunning()
    }
    
    func stopCaptureSession() {
        session.stopRunning()
    }
}

// MARK: - Private methods
extension DetectionViewModel {
    private func addVideoInput(position: AVCaptureDevice.Position) {
        guard let device: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                                    for: .video, position: position) else { return }
        videoDeviceRelay.accept(device)

        if let currentInput = self.deviceInput {
            session.removeInput(currentInput)
            self.deviceInput = nil
        }
        do {
            let input = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(input) {
                session.addInput(input)
                self.deviceInput = input
            }
        } catch {
            print(error)
        }
    }
}
