//
//  MLModelLoaderService.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-20.
//

import Foundation

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
                    coreMLModels.append(.init(url: mlModel, name: mlModelName))
                }
            
            switch location {
            case .bundle:
                mlModelsViewModel.bundledMlModelsRelay.accept(coreMLModels)
            case .downloaded:
                mlModelsViewModel.downloadedModelsRelay.accept(coreMLModels)
            }
            
        } catch {
            print(error)
        }
    }
}
