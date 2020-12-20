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
    private (set) var selectedMLModel = BehaviorRelay<CoreMLModel>(value: .init(url: nil, name: "", origin: .bundle))
    private (set) var isMLModelSelectedRelay = BehaviorRelay<Bool>(value: false)
    
    private (set) var mlModelsSubject = BehaviorRelay<[TableViewSection]>(value: [])
   
    
    private let disposeBag = DisposeBag()
    
    var downloadedModelsObservable: Observable<[CoreMLModel]> {
        return downloadedModelsRelay.asObservable()
    }
    
    var bundledMLModelsObservable: Observable<[CoreMLModel]> {
        return bundledMlModelsRelay.asObservable()
    }
    
    var mlModelsTableViewSectionObservable: Observable<[TableViewSection]> {
        return mlModelsSubject
            .asObservable()
            .observeOn(MainScheduler.instance)
    }
    
    var combinedMlModelsObservable: Observable<[CoreMLModel]> {
        return mlModelsSubject.asObservable()
            .map({ $0.flatMap({ $0.items }) })
    }
    
    var isMLModelSelected: Observable<Bool> {
        return isMLModelSelectedRelay.asObservable()
    }
    
    var dataSource = MLModelSelectionDataSource.dataSource()
    
    init() {
        self.mlModelLoaderService = MLModelLoaderService(mlModelsViewModel: self)
        mlModelLoaderService.loadAllModels(from: .bundle)
        mlModelLoaderService.loadAllModels(from: .downloaded)
        populateTableViewSection()
        setInitialMlModel()
    }
}

// MARK: - Private methods
extension MLModelsViewModel {
    private func populateTableViewSection() {
        var tableViewSections: [TableViewSection] = []
        
        bundledMLModelsObservable.subscribe(onNext: { mlModels in
            tableViewSections.append(TableViewSection(items: mlModels, header: "Bundled models"))
            
        }).disposed(by: disposeBag)
        
        downloadedModelsObservable.subscribe(onNext: { mlModels in
            tableViewSections.append(TableViewSection(items: mlModels, header: "Downloaded models"))
            
        }).disposed(by: disposeBag)
        
        mlModelsSubject.accept(tableViewSections)
    }
    
    private func setInitialMlModel() {
        combinedMlModelsObservable.subscribe(onNext: { [weak self] coreMLModel in
            guard let self = self,
                  let firstItem = coreMLModel[safe: 0] else { return }
            print("first item \(firstItem)")
            self.selectedMLModel.accept(firstItem)
        }).disposed(by: disposeBag)
    }
}
