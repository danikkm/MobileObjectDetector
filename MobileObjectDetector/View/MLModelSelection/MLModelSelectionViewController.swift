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
    
    // MARK: - UI Properties
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Properties
    private var mlModelsViewModel: MLModelsViewModelProtocol!
    
    // MARK: - Reactive Properties
    private let disposeBag = DisposeBag()
    
    // MARK: - Private Computed Properties
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = 70
        tableView
            .translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()
        tableView.refreshControl = refreshControl
        return tableView
        
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyConstraints()
        title = "Available Models"
    }
}

// MARK: - Setup
extension MLModelSelectionViewController {
    public func prepare(viewModel: MLModelsViewModelProtocol) {
        self.mlModelsViewModel = viewModel
    }
    
    private func setup() {
        setupUI()
        setupBindings()
    }
}

// MARK: - Binding
extension MLModelSelectionViewController {
    func setupBindings() {
        mlModelsViewModel.mlModelsTableViewSectionObservable
            .bind(to: tableView.rx.items(dataSource: mlModelsViewModel.dataSource))
            .disposed(by: disposeBag)
        
        refreshControl.rx.controlEvent(.valueChanged)
            .subscribe(onNext: { [weak self] in
                print("here")
                self?.mlModelsViewModel.reloadAllMLModels()
                self?.refreshControl.endRefreshing()
                //                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        
        tableView.rx.itemSelected
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                
                self.mlModelsViewModel.combinedModelsObservable
                    .subscribe(onNext: { [weak self] value in
                        guard let self = self else { return }
                        var index: Int = indexPath.row
                        
                        for i in 0..<indexPath.section {
                            index += self.tableView.numberOfRows(inSection: i)
                        }
                        
                        self.mlModelsViewModel.setSelectedModel(to: value[index])
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
