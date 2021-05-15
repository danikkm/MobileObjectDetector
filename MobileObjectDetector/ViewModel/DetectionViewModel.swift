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

protocol DetectionViewModelEvents: AnyObject {
    func drawVisionRequestResults(_ results: [Any])
    func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation
}

final class DetectionViewModel: BaseViewModel<MLModelsViewModelProtocol>, DetectionViewModelProtocol {
    
    weak var delegate: DetectionViewModelEvents?
    
    private (set) var requests = [VNRequest]()
    
    private let cameraTypeRelay = BehaviorRelay<CameraType>(value: .backFacing)
    private let detectionStateRelay = BehaviorRelay<DetectionState>(value: .inactive)
    private let coreMLModel = PublishSubject<VNCoreMLModel>()
    
    private (set) var session = AVCaptureSession()
    private (set) var bufferSize: CGSize = .zero
    private (set) var deviceInput: AVCaptureDeviceInput!
    private (set) var frameRateRelay = PublishRelay<Double>()
    private var capturePreset: AVCaptureSession.Preset!
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    private var videoDevice: AVCaptureDevice!
    
    var cameraType: CameraType {
        return cameraTypeRelay.value
    }
    
    var detectionStateDriver: Driver<DetectionState> {
        return detectionStateRelay.asDriver(onErrorJustReturn: .inactive).debug()
    }
    
    var detectionState: DetectionState {
        return detectionStateRelay.value
    }
    
    var frameRateObservable: Observable<Double> {
        return frameRateRelay.asObservable().debug()
    }
    
    var cameraTypeObservable: Observable<CameraType> {
        return cameraTypeRelay.asObservable()
    }
    
    var selectedModel: CoreMLModel {
        return model.selectedModel
    }
    
    private var mlModelConfig: MLModelConfiguration {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        return config
    }
    
    private var mlModel: MLModel {
        guard let url = selectedModel.url else {
            fatalError("Invalid URL for the mlmodel")
        }
        
        do {
            return try MLModel(contentsOf: url, configuration: mlModelConfig)
        } catch {
            fatalError("Failed to create VNCoreMLModel: \(error)")
        }
    }
    
    private var visionModel: VNCoreMLModel {
        do {
            return try VNCoreMLModel(for: mlModel)
        } catch {
            fatalError("Failed to create VNCoreMLModel: \(error)")
        }
    }
    
    func setRequests(_ requests: [VNRequest]) {
        self.requests = requests
    }
    
    func configure(delegate: DetectionViewModelEvents) {
        self.delegate = delegate
        self.capturePreset = .vga640x480
    }
}

// MARK: - Public methods
extension DetectionViewModel {
    func prepareAVCapture() {
        addVideoInput(position: .back)
        
        session.beginConfiguration()
        session.sessionPreset = capturePreset ?? .vga640x480 // Model image size is smaller.
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            // Add a video data output
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(delegate as? ObjectRecognitionViewController, queue: videoDataOutputQueue)
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
    
    func setupVision() {
        print("Using: \(selectedModel.name), running on \(mlModelConfig.computeUnits.rawValue)")
        let objectRecognition = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            guard let results = request.results as? [VNRecognizedObjectObservation],
                  let _ = results.first else {
                return
            }
            
            DispatchQueue.main.async { [weak self] in 
                if let results = request.results {
                    self?.delegate?.drawVisionRequestResults(results)
                }
                
                if let _error = error {
                    print(_error.localizedDescription)
                }
            }
        }
        setRequests([objectRecognition])
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

// MARK: - Public Interface
extension DetectionViewModel {
    public func setDetectionState(to state: DetectionState) {
        self.detectionStateRelay.accept(state)
    }
}

// MARK: - Private methods
extension DetectionViewModel {
    private func addVideoInput(position: AVCaptureDevice.Position) {
        guard let device: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                                    for: .video,
                                                                    position: position) else { return }
        videoDevice = device
        
        if let currentInput = deviceInput {
            session.removeInput(currentInput)
            deviceInput = nil
        }
        do {
            let input = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(input) {
                session.addInput(input)
                deviceInput = input
            }
        } catch {
            print(error)
        }
    }
    
    func predictWithPixelBuffer(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var options: [VNImageOption : Any] = [:]
        if let cameraIntrinsicMatrix = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix,
                                                       attachmentModeOut: nil) {
            options[.cameraIntrinsics] = cameraIntrinsicMatrix
        }
        
        
        guard let exifOrientation = delegate?.exifOrientationFromDeviceOrientation() else {
            print("Failed to obtain device orientation")
            return
        }
        
        autoreleasepool {
            var clonePixelBuffer: CVPixelBuffer? = try? pixelBuffer.copy()
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: clonePixelBuffer!,
                                                            orientation: exifOrientation,
                                                            options: options)
            do {
                try imageRequestHandler.perform(requests)
            } catch {
                self.delegate?.drawVisionRequestResults([])
                print(error.localizedDescription)
            }
            clonePixelBuffer = nil
        }
    }
}
