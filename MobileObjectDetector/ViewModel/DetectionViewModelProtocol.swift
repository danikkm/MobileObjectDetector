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
    var detectionStateRelay: PublishRelay<DetectionState> { get }
    var session: AVCaptureSession { get }
    var bufferSize: CGSize { get }
    var detectionStateDriver: Driver<DetectionState> { get }
    
    func configure(delegate: DetectionViewModelEvents)
    func stopCaptureSession()
    func startCaptureSession()
    func switchCamera()
    func prepareAVCapture()
}
