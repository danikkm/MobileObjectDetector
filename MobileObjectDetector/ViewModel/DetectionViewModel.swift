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
    func drawVisionRequestResults(_ observations: [VNRecognizedObjectObservation])
    func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation
}

final class DetectionViewModel: BaseViewModel<MLModelsViewModelProtocol>,
                                DetectionViewModelProtocol {
    
    // MARK: - Private Properties
    private weak var delegate: DetectionViewModelEvents?
    private var requests = [VNRequest]()
    private (set) var session = AVCaptureSession()
    private (set) var bufferSize: CGSize = .zero
    private var deviceInput: AVCaptureDeviceInput!
    private var capturePreset: AVCaptureSession.Preset! = nil
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit)
    private var videoDevice: AVCaptureDevice!
    
    // MARK: - Private Reactive Properties
    private (set) var frameRateRelay = PublishRelay<Double>()
    private let cameraTypeRelay = BehaviorRelay<CameraType>(value: .backFacing)
    private let detectionStateRelay = BehaviorRelay<DetectionState>(value: .inactive)
    private let computeUnitRelay = BehaviorRelay<ComputeUnit>(value: .ane)
    private let coreMLModel = PublishSubject<VNCoreMLModel>()
    
    // MARK: - Public Computed Properties
    var cameraType: CameraType {
        return cameraTypeRelay.value
    }
    
    var detectionState: DetectionState {
        return detectionStateRelay.value
    }
    
    var selectedModel: CoreMLModel {
        return model.selectedModel
    }
    
    // MARK: - Public Reactive Computed Properties
    var detectionStateDriver: Driver<DetectionState> {
        return detectionStateRelay.asDriver(onErrorJustReturn: .inactive).debug()
    }
    
    var frameRateObservable: Observable<Double> {
        return frameRateRelay.asObservable().debug()
    }
    
    var cameraTypeObservable: Observable<CameraType> {
        return cameraTypeRelay.asObservable()
    }
    
    // MARK: - Private Computed Properties
    private var mlModelConfig: MLModelConfiguration {
        let config = MLModelConfiguration()
        
        switch computeUnitRelay.value {
        case .ane:
            config.computeUnits = .all
        case .gpu:
            config.computeUnits = .cpuAndGPU
        case .cpu:
            config.computeUnits = .cpuOnly
        }
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
}

// MARK: - Public methods
extension DetectionViewModel {
    func configure(delegate: DetectionViewModelEvents) {
        self.delegate = delegate
        self.capturePreset = .vga640x480
    }
    
    func prepareAVCapture() {
        addVideoInput(deviceType: .builtInDualWideCamera, position: .back)
        
        session.beginConfiguration()
        session.sessionPreset = capturePreset ?? .vga640x480 // Model image size is smaller.
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            // Add a video data output
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
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
        visionModel.featureProvider = ThresholdProvider()
        
        let objectRecognition = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            self?.detectionRequestHandler(request: request, error: error)
        }
        objectRecognition.imageCropAndScaleOption = .scaleFit
        requests = [objectRecognition]
    }
    
    func switchCamera() {
        switch cameraType {
        case .frontFacing:
            cameraTypeRelay.accept(.backFacing)
            addVideoInput(deviceType: .builtInDualWideCamera, position: .back)
            videoDevice.set(frameRate: 60.0)
        case .backFacing:
            cameraTypeRelay.accept(.frontFacing)
            addVideoInput(deviceType: .builtInWideAngleCamera, position: .front)
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
        detectionStateRelay.accept(state)
    }
    
    public func setComputeUnit(to computeUnit: ComputeUnit) {
        computeUnitRelay.accept(computeUnit)
    }
    
    public func changeZoomFactor() {
        var zoomFactor: CGFloat = 1.0
        
        switch videoDevice.deviceType {
        case .builtInDualWideCamera where videoDevice.videoZoomFactor == 1.0:
            zoomFactor = 2.0
        case .builtInDualWideCamera where videoDevice.videoZoomFactor == 2.0:
            zoomFactor = 1.0
        default:
            break
        }
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.videoZoomFactor = zoomFactor
            videoDevice.unlockForConfiguration()
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
        
        autoreleasepool { [weak self] in
            guard let self = self else { return }
            
            var clonePixelBuffer: CVPixelBuffer? = try? pixelBuffer.copy()
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: clonePixelBuffer!,
                                                            orientation: exifOrientation,
                                                            options: options)
            do {
                let startTime = CACurrentMediaTime()
                try imageRequestHandler.perform(self.requests)
                let endTime = CACurrentMediaTime()
                print(String(format: "Inference (ms): %.3f", (endTime - startTime) * 1000))
            } catch {
                self.delegate?.drawVisionRequestResults([])
                print(error)
            }
            clonePixelBuffer = nil
        }
    }
    
    public func cleanup() {
        //        requests = [] // TODO: is it needed
        delegate?.drawVisionRequestResults([])
    }
}

// MARK: - Private methods
extension DetectionViewModel {
    // TODO: Add support for other devices!
    private func addVideoInput(deviceType: AVCaptureDevice.DeviceType,
                               position: AVCaptureDevice.Position) {
        guard let device: AVCaptureDevice = AVCaptureDevice.default(deviceType,
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
    
    private func detectionRequestHandler(request: VNRequest, error: Error?) {
        if let _error = error {
            print("An error occurred with the vision request: \(_error.localizedDescription)")
            return
        }
        guard let request = request as? VNCoreMLRequest else {
            print("Vision request is not a VNCoreMLRequest")
            return
        }
        
        guard let observations = request.results as? [VNRecognizedObjectObservation],
              let _ = observations.first else {
            print("Request did not return recognized objects: \(request.results?.debugDescription ?? "[No results]")")
            return
        }
        
        guard !observations.isEmpty else {
            cleanup()
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.drawVisionRequestResults(observations)
        }
    }
}
