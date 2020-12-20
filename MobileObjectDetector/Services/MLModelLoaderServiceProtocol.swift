//
//  MLModelLoaderServiceProtocol.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-20.
//

import Foundation

protocol MLModelLoaderServiceProtocol: class {
    func loadAllModels(from location: CoreMLModelLocation)
}
