//
//  MLModelsViewModelProtocol.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-20.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

protocol MLModelsViewModelProtocol: AnyObject {
    var selectedModel: CoreMLModel { get }
    
    var dataSource: RxTableViewSectionedReloadDataSource<TableViewSection> { get }
    var downloadedModelsObservable: Observable<[CoreMLModel]> { get }
    var mlModelsTableViewSectionObservable: Observable<[TableViewSection]> { get }
    var combinedModelsObservable: Observable<[CoreMLModel]> { get }
    var selectedModelDriver: Driver<CoreMLModel> { get }
    
    func compileMLModel(at selectedFileURL: URL, originalName: String) -> URL?
    func reloadAllMLModels()
    
    func setSelectedModel(to selectedModel: CoreMLModel)
    func setModels(_ models: [CoreMLModel], to location: CoreMLModelLocation)
}
