//
//  MLModelLoaderService.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-20.
//

import Foundation
import CoreML

enum CoreMLModelLocation {
    case bundle
    case downloaded
}

class MLModelLoaderService: MLModelLoaderServiceProtocol {
    private let mlModelsViewModel: MLModelsViewModelProtocol
    
    init(mlModelsViewModel: MLModelsViewModelProtocol) {
        self.mlModelsViewModel = mlModelsViewModel
    }
    
    func loadAllModels(from location: CoreMLModelLocation) {
        var documentsUrl: URL
        
        switch location {
        case .bundle:
            documentsUrl = Bundle.main.bundleURL
        case .downloaded:
            documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
            var coreMLModels: [CoreMLModel] = []
            
            directoryContents
                .filter { $0.pathExtension == "mlmodelc" }
                .forEach { mlModel in
                    let mlModelName = mlModel.deletingPathExtension().lastPathComponent
                    coreMLModels.append(.init(url: mlModel, name: mlModelName, origin: location))
                }
            
            switch location {
            case .bundle:
                mlModelsViewModel.setModels(coreMLModels, to: .bundle)
            case .downloaded:
                mlModelsViewModel.setModels(coreMLModels, to: .downloaded)
            }
            
        } catch {
            print(error)
        }
    }
    
    func compileMLModel(at selectedFileURL: URL, originalName: String) -> URL? {
        do {
            let compilePath = try MLModel.compileModel(at: selectedFileURL)
            
            return compilePath
        } catch {
            print(error, "Compile error")
            return nil
        }
    }
}
