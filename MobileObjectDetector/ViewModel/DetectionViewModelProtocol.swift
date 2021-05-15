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
    var requests: [VNRequest] { get }
    var cameraType: CameraType { get }
    var session: AVCaptureSession { get }
    var bufferSize: CGSize { get }
    var frameRateRelay: PublishRelay<Double> { get }
    var detectionStateDriver: Driver<DetectionState> { get }
    var detectionState: DetectionState { get }
    var frameRateObservable: Observable<Double> { get }
    var cameraTypeObservable: Observable<CameraType> { get }
    
    var selectedModel: CoreMLModel { get }
    
    func configure(delegate: DetectionViewModelEvents)
    func stopCaptureSession()
    func startCaptureSession()
    func prepareAVCapture()
    func setupVision()
    func predictWithPixelBuffer(sampleBuffer: CMSampleBuffer)
    func switchCamera()
    func changeFrameRate(to frameRate: Double)
    func setDetectionState(to state: DetectionState)
    
    func setRequests(_ requests: [VNRequest]) 
}
