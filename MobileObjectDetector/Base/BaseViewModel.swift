//
//  BaseViewModel.swift
//  MobileObjectDetector
//
//  Created by Daniel on 2021-05-14.
//

import Foundation

public class BaseViewModel<Model> {
    public var model: Model
    
    init(model: Model) {
        self.model = model
        prepare()
    }
    
    func prepare() {}
    func configure(model: Model) {}
}
