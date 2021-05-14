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
    
    private (set) var mlModelLoaderService: MLModelLoaderServiceProtocol!
    private (set) var bundledMlModelsRelay = BehaviorRelay<[CoreMLModel]>(value: [])
    private (set) var downloadedModelsRelay = BehaviorRelay<[CoreMLModel]>(value: [])
    private (set) var selectedModelRelay = BehaviorRelay<CoreMLModel>(value: .init(url: nil, name: "", origin: .bundle))
    
    private (set) var mlModelsSubject = BehaviorRelay<[TableViewSection]>(value: [])
    
    private let disposeBag = DisposeBag()
    
    var downloadedModelsObservable: Observable<[CoreMLModel]> {
        return downloadedModelsRelay.asObservable()
    }
    
    var bundledModelsObservable: Observable<[CoreMLModel]> {
        return bundledMlModelsRelay.asObservable()
    }
    
    var mlModelsTableViewSectionObservable: Observable<[TableViewSection]> {
        return mlModelsSubject
            .asObservable()
            .observe(on: MainScheduler.instance)
    }
    
    var combinedModelsObservable: Observable<[CoreMLModel]> {
        return mlModelsSubject.asObservable()
            .map({ $0.flatMap({ $0.items }) })
    }
    
    var selectedModelDriver: Driver<CoreMLModel> {
        return selectedModelRelay.asDriver(onErrorJustReturn: .init(url: nil, name: "", origin: .bundle))
    }
    
    var selectedModel: CoreMLModel {
        return selectedModelRelay.value
    }
    
    var dataSource = MLModelSelectionDataSource.dataSource()
    
    init() {
        self.mlModelLoaderService = MLModelLoaderService(mlModelsViewModel: self)
        mlModelLoaderService.loadAllModels(from: .bundle)
        mlModelLoaderService.loadAllModels(from: .downloaded)
        populateTableViewSection()
        setInitialMlModel()
    }
    
    func compileMLModel(at selectedFileURL: URL, originalName: String) -> URL? {
        return mlModelLoaderService.compileMLModel(at: selectedFileURL, originalName: originalName)
    }
    
    func reloadAllMLModels() {
        downloadedModelsRelay.accept([])
        mlModelLoaderService.loadAllModels(from: .downloaded)
        mlModelsSubject.accept([])
        populateTableViewSection()
        
    }
}

// MARK: - Private methods
extension MLModelsViewModel {
    private func populateTableViewSection() {
        var tableViewSections: [TableViewSection] = []
        
        bundledModelsObservable.subscribe(onNext: { mlModels in
            tableViewSections.append(TableViewSection(items: mlModels, header: "Bundled models"))
            
        }).disposed(by: disposeBag)
        
        
        downloadedModelsObservable.subscribe(onNext: { mlModels in
            tableViewSections.append(TableViewSection(items: mlModels, header: "Downloaded models"))
            
        }).disposed(by: disposeBag)
        
        mlModelsSubject.accept(tableViewSections)
    }
    
    private func setInitialMlModel() {
        combinedModelsObservable.subscribe(onNext: { [weak self] coreMLModel in
            guard let self = self,
                  let firstItem = coreMLModel[safe: 0] else { return }
            
            self.selectedModelRelay.accept(firstItem)
        }).disposed(by: disposeBag)
    }
}
