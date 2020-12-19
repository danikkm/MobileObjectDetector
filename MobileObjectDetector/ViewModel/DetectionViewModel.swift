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

enum CameraType {
    case frontFacing
    case backFacing
}

enum DetectionState {
    case inactive
    case active
}

protocol DetectionViewModelEvents: class {
}

final class DetectionViewModel {
    weak var delegate: DetectionViewModelEvents?
    
    let cameraTypeRelay = BehaviorRelay<CameraType>(value: .backFacing)
    
    var cameraType: CameraType {
        return cameraTypeRelay.value
    }
    
    let detectionState = PublishRelay<DetectionState>()
    
    var deviceInput: AVCaptureDeviceInput!
    let session = AVCaptureSession()
    let capturePreset: AVCaptureSession.Preset?
    let videoDataOutput = AVCaptureVideoDataOutput()
    let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    var bufferSize: CGSize = .zero
    
    let coreMLModel = PublishSubject<VNCoreMLModel>()
    
    
    var detectionStateDriver: Driver<DetectionState> {
        return detectionState.asDriver(onErrorJustReturn: .inactive)
    }
    
    var cameraTypeObservable: Observable<CameraType> {
        return cameraTypeRelay.asObservable()
    }
    
    init() {
        // TODO: put it in the init
        self.capturePreset = .hd1280x720
    }
    
    func configure(delegate: DetectionViewModelEvents) {
        self.delegate = delegate
    }
}

extension DetectionViewModel {
    func prepareAVCapture() {
        // Select a video device, make an input
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
        
        do {
            self.deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = capturePreset ?? .hd1280x720 // Model image size is smaller.
        
        // Add a video input
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
            try  videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        session.commitConfiguration()
    }
    
    func addVideoInput(position: AVCaptureDevice.Position) {
        guard let device: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                                    for: .video, position: position) else { return }
        if let currentInput = self.deviceInput {
            session.removeInput(currentInput)
            self.deviceInput = nil
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                self.deviceInput = input
            }
        } catch {
            print(error)
        }
    }
    
    func switchCamera() {
        switch cameraType{
        case .frontFacing:
            self.cameraTypeRelay.accept(.backFacing)
            self.addVideoInput(position: .back)
        case .backFacing:
            self.cameraTypeRelay.accept(.frontFacing)
            self.addVideoInput(position: .front)
        }
        //configure your session here
        DispatchQueue.main.async {
            self.session.beginConfiguration()
            if self.session.canAddOutput(self.videoDataOutput) {
                self.session.addOutput(self.videoDataOutput)
            }
            self.session.commitConfiguration()
        }
    }
    
    func getCamera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceDescoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: .video, position: .unspecified)
        return deviceDescoverySession.devices.first(where: { $0.position == position })
    }
    
    func startCaptureSession() {
        session.startRunning()
    }
    
    func stopCaptureSession() {
        session.stopRunning()
    }
}
