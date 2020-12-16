//
//  DetectionViewModel.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-16.
//

import Foundation
import RxSwift
import RxCocoa

enum CameraType {
    case frontFacing
    case backFacing
}

enum DetectionState {
    case inactive
    case active
    case error
}

final class DetectionViewModel {
    let cameraType = BehaviorRelay<CameraType>(value: .backFacing)
    let detectionState = PublishRelay<DetectionState>()
    
    // TODO: Should be driver
    var detectionStateObservable: Observable<DetectionState> {
        return detectionState.asObservable().observe(on: MainScheduler.asyncInstance)
    }
}
