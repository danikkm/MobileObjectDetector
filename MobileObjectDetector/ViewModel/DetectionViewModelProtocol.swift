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
    var session: AVCaptureSession { get }
    var bufferSize: CGSize { get }
    
    var frameRateRelay: PublishRelay<Double> { get }
    
    var cameraType: CameraType { get }
    var detectionState: DetectionState { get }
    var selectedModel: CoreMLModel { get }
    
    var detectionStateDriver: Driver<DetectionState> { get }
    var frameRateObservable: Observable<Double> { get }
    var cameraTypeObservable: Observable<CameraType> { get }
    
    func configure(delegate: DetectionViewModelEvents)
    func stopCaptureSession()
    func startCaptureSession()
    func prepareAVCapture()
    func setupVision()
    func predictWithPixelBuffer(sampleBuffer: CMSampleBuffer)
    func switchCamera()
    func changeFrameRate(to frameRate: Double)
    
    func setDetectionState(to state: DetectionState)
    func setComputeUnit(to computeUnit: ComputeUnit)
    func cleanup()
}
