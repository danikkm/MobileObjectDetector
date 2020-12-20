//
//  MLModelItemViewModel.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-20.
//

import Foundation

struct MLModelItemViewModel {
    var name: String
    
    init(itemModel: CoreMLModel) {
        self.name = itemModel.name
    }
}
