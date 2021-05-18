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
    
    // MARK: - Private Reactive Properties
    private let frameRateSwitchRelay = BehaviorRelay<FrameRateMode>(value: .smooth)
    private let isFrameRateToggleEnabledRelay = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Public Computed Properties
    public var frameRateSwitch: Bool {
        return frameRateSwitchRelay.value == .smooth ? true : false
    }
    
    public var isFrameRateToggleEnabled: Bool {
        return isFrameRateToggleEnabledRelay.value
    }
    
    // MARK: - Public Reactive Computed Properties
    public var frameRateObservable: Observable<FrameRateMode> {
        return frameRateSwitchRelay.asObservable()
    }
}

// MARK: - Public Interface
extension SettingsViewModel {
    public func setFrameRate(to frameRate: FrameRateMode) {
        frameRateSwitchRelay.accept(frameRate)
    }
    
    public func setIsFrameRateToggleEnabled(to value: Bool) {
        isFrameRateToggleEnabledRelay.accept(value)
    }
}
