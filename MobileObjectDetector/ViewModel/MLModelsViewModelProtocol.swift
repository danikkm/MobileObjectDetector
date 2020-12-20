//
//  MLModelsViewModelProtocol.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-20.
//

import RxSwift
import RxCocoa
import RxDataSources

protocol MLModelsViewModelProtocol: class {
    var bundledMlModelsRelay: BehaviorRelay<[CoreMLModel]> { get }
    var downloadedModelsRelay: BehaviorRelay<[CoreMLModel]> { get }
    var downloadedModelsObservable: Observable<[CoreMLModel]> { get }
    var mlModelsTableViewSectionObservable: Observable<[TableViewSection]> { get }
    var combinedMlModelsObservable: Observable<[CoreMLModel]> { get }
    var dataSource: RxTableViewSectionedReloadDataSource<TableViewSection> { get }
}
