//
//  MLModelSelectionDataSource.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-20.
//

import Foundation
import UIKit
import RxDataSources

struct TableViewSection {
    let items: [CoreMLModel]
    let header: String

    init(items: [CoreMLModel], header: String) {
        self.items = items
        self.header = header
    }
}

extension TableViewSection: SectionModelType {
    typealias Item = CoreMLModel

    init(original: Self, items: [Self.Item]) {
        self = original
    }
}

struct MLModelSelectionDataSource {
    typealias DataSource = RxTableViewSectionedReloadDataSource
    
    static func dataSource() -> DataSource<TableViewSection> {
        return .init(configureCell: { dataSource, tableView, indexPath, item -> UITableViewCell in
            
            let cell = MLModelSelectionTableViewCell()
            cell.viewModel = MLModelItemViewModel(itemModel: item)
            return cell
        }
        , titleForHeaderInSection: { dataSource, index in
            return dataSource.sectionModels[index].header
        })
    }
}
