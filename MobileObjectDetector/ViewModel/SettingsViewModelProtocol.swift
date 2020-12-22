//
//  SettingsViewModelProtocol.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-22.
//

import RxSwift
import RxCocoa

protocol SettingsViewModelProtocol {
    var frameRateSwitchRelay: BehaviorRelay<FrameRateMode> { get }
    var isFrameRateToggleEnabledRelay: BehaviorRelay<Bool> { get }
    var frameRateSwitch: Bool { get }
    var isFrameRateToggleEnabled: Bool { get }
}
