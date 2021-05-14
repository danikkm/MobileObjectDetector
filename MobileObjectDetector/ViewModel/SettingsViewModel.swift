//
//  SettingsViewModel.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-22.
//

import Foundation
import RxSwift
import RxCocoa

final class SettingsViewModel: SettingsViewModelProtocol {
    
    private (set) var frameRateSwitchRelay = BehaviorRelay<FrameRateMode>(value: .smooth)
    private (set) var isFrameRateToggleEnabledRelay = BehaviorRelay<Bool>(value: false)
    
    var frameRateToggleDriver: Driver<FrameRateMode> {
        return frameRateSwitchRelay.asDriver(onErrorJustReturn: .smooth)
    }
    
    var frameRateSwitch: Bool {
        return frameRateSwitchRelay.value == .smooth ? true : false
    }
    
    var isFrameRateToggleEnabled: Bool {
        return isFrameRateToggleEnabledRelay.value
    }
}
