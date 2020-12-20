//
//  MLModelSelectionTableViewCell.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-20.
//

import Foundation
import UIKit

class MLModelSelectionTableViewCell: UITableViewCell {
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Properties
    var viewModel: MLModelItemViewModel! {
        didSet {
            // TODO: refactor
            self.configure()
        }
    }
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
}

// MARK: - Configuration
extension MLModelSelectionTableViewCell {
    private func configure() {
        self.nameLabel.text = viewModel.name
    }
}

// MARK: - UI Setup
extension MLModelSelectionTableViewCell {
    private func setupUI() {
        self.contentView.addSubview(nameLabel)
        
        nameLabel.centerXAnchor
            .constraint(equalTo: self.contentView.centerXAnchor)
            .isActive = true
        
        nameLabel.centerYAnchor
            .constraint(equalTo: self.contentView.centerYAnchor)
            .isActive = true
    }
}
