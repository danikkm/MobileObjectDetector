//
//  DetectionViewModelProtocol.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-19.
//

import RxSwift
import RxCocoa
import AVFoundation

protocol DetectionViewModelProtocol {
    var cameraType: CameraType { get }
    var detectionStateRelay: PublishRelay<DetectionState> { get }
    var session: AVCaptureSession { get }
    var bufferSize: CGSize { get }
    var frameRateRelay: PublishRelay<Double> { get }
    var detectionStateDriver: Driver<DetectionState> { get }
    var frameRateObservable: Observable<Double> { get }
    var cameraTypeObservable: Observable<CameraType> { get }
    
    func configure(delegate: DetectionViewModelEvents)
    func stopCaptureSession()
    func startCaptureSession()
    func prepareAVCapture()
    func switchCamera()
    func changeFrameRate(to frameRate: Double)
}
