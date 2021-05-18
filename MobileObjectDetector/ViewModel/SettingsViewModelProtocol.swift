//
//  SettingsViewModelProtocol.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-22.
//

import RxSwift
import RxCocoa

protocol SettingsViewModelProtocol {
    var frameRateSwitch: Bool { get }
    var isFrameRateToggleEnabled: Bool { get }
    
    var frameRateObservable: Observable<FrameRateMode> { get }
    
    func setFrameRate(to frameRate: FrameRateMode)
    func setIsFrameRateToggleEnabled(to value: Bool)
}
