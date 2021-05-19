//
//  DetectionViewModelProtocol.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-19.
//

import RxSwift
import RxCocoa
import AVFoundation
import Vision

protocol DetectionViewModelProtocol: AnyObject {
    var model: MLModelsViewModelProtocol { get }
    var session: AVCaptureSession { get }
    var bufferSize: CGSize { get }
    
    var cameraType: CameraType { get }
    var detectionState: DetectionState { get }
    var selectedModel: CoreMLModel { get }
    
    var currentZoomFactorText: Driver<String> { get }
    var detectionStateDriver: Driver<DetectionState> { get }
    var cameraTypeObservable: Observable<CameraType> { get }
    var inferenceTimeDriver: Driver<String> { get }
    
    func configure(delegate: DetectionViewModelEvents)
    func stopCaptureSession()
    func startCaptureSession()
    func prepareAVCapture()
    func setupVision()
    func predictWithPixelBuffer(sampleBuffer: CMSampleBuffer)
    func switchCamera()
    
    func setDetectionState(to state: DetectionState)
    func setComputeUnit(to computeUnit: ComputeUnit)
    func setFrameRate(to frameRate: FrameRateMode)
    func setIouThreshold(to iou: Double)
    func setConfidenceThreshold(to confidence: Double)
    func changeZoomFactor()
    func cleanup()
}
