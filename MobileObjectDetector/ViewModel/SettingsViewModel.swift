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
    
    // MARK: - Private Properties
    private let defaults = UserDefaults.standard
    
    // MARK: - Private Reactive Properties
    private let isFrameRateToggleEnabledRelay = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Private Computed Properties
    private var frameRateMode: FrameRateMode { //TODO: is there a better way of doing it?
        guard let data = defaults.data(forKey: "FrameRateMode"),
              let stored = try? JSONDecoder().decode(FrameRateMode.self, from: data)
        else {
            return .smooth
        }
        return stored
    }
    
    // MARK: - Public Computed Properties
    public var frameRateSwitch: Bool {
        return frameRateMode == .smooth ? true : false
    }
    
    public var isFrameRateToggleEnabled: Bool {
        return isFrameRateToggleEnabledRelay.value
    }
    
    // MARK: - Public Reactive Computed Properties
    public var frameRateObservable: Observable<FrameRateMode> {
        return defaults.rx.observe(Data.self, "FrameRateMode").flatMap { data -> Observable<FrameRateMode> in
            guard let _data = data else { return Observable.just(.smooth)}
            return Observable<FrameRateMode>.create { obs -> Disposable in
                guard let stored = try? JSONDecoder()
                        .decode(FrameRateMode.self, from: _data)
                else {
                    return Disposables.create()
                }
                obs.onNext(stored)
                return Disposables.create()
            }
        }
    }
}

// MARK: - Public Interface
extension SettingsViewModel {
    public func setFrameRate(to frameRate: FrameRateMode) {
        if let encoded = try? JSONEncoder().encode(frameRate) {
            UserDefaults.standard.setValue(encoded, forKey: "FrameRateMode")
        }
    }
    
    public func setIsFrameRateToggleEnabled(to value: Bool) {
        isFrameRateToggleEnabledRelay.accept(value)
    }
}
