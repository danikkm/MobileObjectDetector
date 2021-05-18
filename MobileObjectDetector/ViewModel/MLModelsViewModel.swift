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
    
    // MARK: - Private Properties
    private (set) var mlModelLoaderService: MLModelLoaderServiceProtocol!
    
    // MARK: - Private Reactive Properties
    private let disposeBag = DisposeBag()
    private let bundledMlModelsRelay = BehaviorRelay<[CoreMLModel]>(value: [])
    private let downloadedModelsRelay = BehaviorRelay<[CoreMLModel]>(value: [])
    private let selectedModelRelay = BehaviorRelay<CoreMLModel>(value: .init(url: nil, name: "", origin: .bundle))
    private let mlModelsSubject = BehaviorRelay<[TableViewSection]>(value: [])
    private (set) var dataSource = MLModelSelectionDataSource.dataSource()
    
    // MARK: - Public Computed Properties
    public var selectedModel: CoreMLModel {
        return selectedModelRelay.value
    }
    
    // MARK: - Public Reactive Computed Properties
    public var downloadedModelsObservable: Observable<[CoreMLModel]> {
        return downloadedModelsRelay.asObservable()
    }
    
    public var bundledModelsObservable: Observable<[CoreMLModel]> {
        return bundledMlModelsRelay.asObservable()
    }
    
    public var mlModelsTableViewSectionObservable: Observable<[TableViewSection]> {
        return mlModelsSubject
            .asObservable()
            .observe(on: MainScheduler.instance)
    }
    
    public var combinedModelsObservable: Observable<[CoreMLModel]> {
        return mlModelsSubject.asObservable()
            .map({ $0.flatMap({ $0.items }) })
    }
    
    public var selectedModelDriver: Driver<CoreMLModel> {
        return selectedModelRelay.asDriver(onErrorJustReturn: .init(url: nil, name: "", origin: .bundle))
    }
}

// MARK: - Public methods
extension MLModelsViewModel {
    public func configure() {
        self.mlModelLoaderService = MLModelLoaderService(mlModelsViewModel: self)
        mlModelLoaderService.loadAllModels(from: .bundle)
        mlModelLoaderService.loadAllModels(from: .downloaded)
        populateTableViewSection()
        setInitialMlModel()
    }
    
    public func compileMLModel(at selectedFileURL: URL, originalName: String) -> URL? {
        return mlModelLoaderService.compileMLModel(at: selectedFileURL, originalName: originalName)
    }
    
    public func reloadAllMLModels() {
        downloadedModelsRelay.accept([])
        mlModelLoaderService.loadAllModels(from: .downloaded)
        mlModelsSubject.accept([])
        populateTableViewSection()
    }
}

// MARK: - Public Interface
extension MLModelsViewModel {
    public func setSelectedModel(to selectedModel: CoreMLModel) {
        selectedModelRelay.accept(selectedModel)
    }
    
    public func setModels(_ models: [CoreMLModel], to location: CoreMLModelLocation) {
        switch location {
        case .bundle:
            bundledMlModelsRelay.accept(models)
        case .downloaded:
            downloadedModelsRelay.accept(models)
        }
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
