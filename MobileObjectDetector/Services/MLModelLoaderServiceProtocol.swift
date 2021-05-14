//
//  MLModelLoaderServiceProtocol.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-20.
//

import Foundation

protocol MLModelLoaderServiceProtocol: AnyObject {
    func loadAllModels(from location: CoreMLModelLocation)
    func compileMLModel(at selectedFileURL: URL, originalName: String) -> URL?
}
