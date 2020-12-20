//
//  CoreMLModel.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-20.
//

import Foundation

struct CoreMLModel {
    let url: URL?
    let name: String
    let origin: CoreMLModelLocation
    
    init(url: URL?, name: String, origin: CoreMLModelLocation) {
        self.url = url
        self.name = name
        self.origin = origin
    }
}
