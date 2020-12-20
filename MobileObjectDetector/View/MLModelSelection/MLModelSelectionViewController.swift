//
//  MLModelSelectionViewController.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-20.
//

import Foundation
import UIKit
import RxSwift
import RxDataSources

class MLModelSelectionViewController: UIViewController {
    
    var mlModelsViewModel: MLModelsViewModelProtocol!
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyConstraints()
        title = "ML Model Selection"
    }
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = 70
        tableView
            .translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()
        return tableView
        
    }()
    
    func prepare(viewModel: MLModelsViewModelProtocol) {
        self.mlModelsViewModel = viewModel
    }
}

// MARK: - Binding
extension MLModelSelectionViewController {
    func bindTableView() {
        mlModelsViewModel.mlModelsTableViewSectionObservable
            .bind(to: tableView.rx.items(dataSource: mlModelsViewModel.dataSource))
            .disposed(by: disposeBag)
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                let cell = self.tableView.cellForRow(at: indexPath)
                var index: Int = indexPath.row
                
                for i in 0..<indexPath.section {
                    index += self.tableView.numberOfRows(inSection: i)
                }
                                
                self.mlModelsViewModel.combinedMlModelsObservable.subscribe(onNext: { [unowned self] value in
                    print(value[index].name)
                }).disposed(by: self.disposeBag)
            }).disposed(by: disposeBag)
    }
}

// MARK: - UI Setup
extension MLModelSelectionViewController {
    private func setupUI() {
        self.view.backgroundColor = .white
        self.view.addSubview(tableView)
    }
    
    private func applyConstraints() {
        tableView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        tableView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
    }
}
