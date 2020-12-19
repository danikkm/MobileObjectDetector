//
//  MLModelLoaderService.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-20.
//

import Foundation

class MLModelLoaderService {
    private let mlModelsViewModel: MLModelsViewModelProtocol
    
    init(mlModelsViewModel: MLModelsViewModelProtocol) {
        self.mlModelsViewModel = mlModelsViewModel
    }
    
    func loadAllDownloadedModels() {
        
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)

            var coreMLModels: [CoreMLModel] = []
            directoryContents
                .filter { $0.pathExtension == "mlmodel" }
                .forEach { mlModel in
                    let mlModelName = mlModel.deletingPathExtension().lastPathComponent
                    coreMLModels.append(.init(url: mlModel, name: mlModelName))
            }
            
            mlModelsViewModel.downloadedModelsRelay.accept(coreMLModels)

        } catch {
            print(error)
        }
    }
}
