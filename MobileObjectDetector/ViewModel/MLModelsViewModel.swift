//
//  MLModelsViewModel.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-20.
//

import Foundation
import RxSwift
import RxCocoa

final class MLModelsViewModel: MLModelsViewModelProtocol {
    // TODO: add protocol
    private (set) var mlModelLoaderService: MLModelLoaderService!
    private (set) var bundledMlModelsRelay = BehaviorRelay<[CoreMLModel]>(value: [])
    private (set) var downloadedModelsRelay = BehaviorRelay<[CoreMLModel]>(value: [])
    
    var downloadedModelsObservable: Observable<[CoreMLModel]> {
        return downloadedModelsRelay.asObservable()
    }
    
    init() {
        self.mlModelLoaderService = MLModelLoaderService(mlModelsViewModel: self)
    }
    
    func test() {
        mlModelLoaderService.loadAllDownloadedModels()
        print(downloadedModelsRelay.value.forEach {
            print($0.url," and:", $0.name)
        })
    }
}

struct CoreMLModel {
    let url: URL
    let name: String
    
    init(url: URL, name: String) {
        self.url = url
        self.name = name
    }
}
