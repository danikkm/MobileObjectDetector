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
    
//    private var mlModelsViewModel: MLModelsViewModelProtocol!
    private var detectionViewModel: DetectionViewModel!
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyConstraints()
        title = "Available Models"
    }
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = 70
        tableView
            .translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()
        tableView.refreshControl = refreshControl
        return tableView
        
    }()
    
    func prepare(viewModel: DetectionViewModel) {
        self.detectionViewModel = viewModel
        self.detectionViewModel.model.reloadAllMLModels()
//        self.detectionViewModel
    }
}

// MARK: - Binding
extension MLModelSelectionViewController {
    func setupBindings() {
        detectionViewModel.model.mlModelsTableViewSectionObservable
            .bind(to: tableView.rx.items(dataSource: detectionViewModel.model.dataSource))
            .disposed(by: disposeBag)
        
        refreshControl.rx.controlEvent(.valueChanged)
            .subscribe(onNext: { [weak self] in
                print("here")
                self?.detectionViewModel.model.reloadAllMLModels()
                self?.refreshControl.endRefreshing()
//                self?.tableView.reloadData()
        })
        .disposed(by: disposeBag)
        
        
        tableView.rx.itemSelected
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                
                self.detectionViewModel.model.combinedModelsObservable
                    .subscribe(onNext: { [weak self] value in
                        guard let self = self else { return }
                        var index: Int = indexPath.row
                        
                        for i in 0..<indexPath.section {
                            index += self.tableView.numberOfRows(inSection: i)
                        }
                        
                        self.detectionViewModel.model.selectedModelRelay.accept(value[index])
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
