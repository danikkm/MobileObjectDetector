//
//  DetectionViewModel.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-16.
//

import Foundation
import RxSwift
import RxCocoa
import Vision

enum CameraType {
    case frontFacing
    case backFacing
}

enum DetectionState {
    case inactive
    case active
}

final class DetectionViewModel {
    let cameraType = BehaviorRelay<CameraType>(value: .backFacing)
    let detectionState = PublishRelay<DetectionState>()
    
    let coreMLModel = PublishSubject<VNCoreMLModel>()
    
    
    var detectionStateDriver: Driver<DetectionState> {
        return detectionState.asDriver(onErrorJustReturn: .inactive)
    }
}
