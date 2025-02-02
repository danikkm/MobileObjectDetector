//
//  SettingsViewController.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-18.
//

import UIKit
import QuickTableViewController
import CoreML
import RxSwift
import RxDataSources
import NotificationBannerSwift

// TODO: refactor using using vanilla table view
class SettingsViewController: QuickTableViewController {
    
    private var settingsViewModel: SettingsViewModelProtocol!
    private var detectionViewModel: DetectionViewModelProtocol!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainUIElements()
        setupAdditionalUIElements()
        setupBindings()
    }
    
    func prepare(detectionViewModel: DetectionViewModelProtocol) {
        self.detectionViewModel = detectionViewModel
        self.settingsViewModel = SettingsViewModel()
    }
    
    private func setupMainUIElements() {
        tableContents = [
            Section(title: "Camera Settings", rows: [
                SwitchRow<CustomSwitchCell>(text: "60 FPS", switchValue: settingsViewModel.frameRateSwitch, action: self.didToggleFrameRateSection())
            ]),
            Section(title: "Select Model", rows: [
                TapActionRow(text: "Open List of Models", action: { [weak self] _ in
                    guard let self = self else { return }
                    
                    let mlModelSelectionVC = MLModelSelectionViewController()
                    mlModelSelectionVC.prepare(viewModel: self.detectionViewModel.model)
                    self.navigationController?.pushViewController(mlModelSelectionVC, animated: true)
                })
            ]),
            Section(title: "Import models", rows: [
                TapActionRow(text: "Open Files", action: { [weak self] _ in
                    guard let self = self else { return }
                    
                    // TODO: fix errors/warnings when trying to import
                    // TODO: add only mlmodel extension
                    let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
                    documentPicker.delegate = self
                    documentPicker.allowsMultipleSelection = false
                    self.present(documentPicker, animated: true, completion: nil)
                })
            ])
        ]
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        (cell as? CustomSwitchCell)?.configure(isSwitchControlEnabled: self.settingsViewModel.isFrameRateToggleEnabled)
        return cell
    }
    
    private func setupAdditionalUIElements() {
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Settings"
        view.backgroundColor = .white
        navigationController?.navigationBar.tintColor = UIColor.SystemItem.cyan
        
    }
    
    private func setupBindings() {
        detectionViewModel.cameraTypeObservable
            .subscribe(onNext: { [weak self] cameraType in
                switch cameraType {
                case .frontFacing:
                    self?.settingsViewModel.setIsFrameRateToggleEnabled(to: false)
                case .backFacing:
                    self?.settingsViewModel.setIsFrameRateToggleEnabled(to: true)
                }
            }).disposed(by: disposeBag)
        
        settingsViewModel.frameRateObservable
            .subscribe(onNext: { [weak self] frameRate in
                self?.detectionViewModel.setFrameRate(to: frameRate)
            }).disposed(by: disposeBag)
    }
}

// MARK: - Actions
extension SettingsViewController {
    private func didToggleFrameRateSection() -> (Row) -> Void {
        return { [weak self] row in
            if let toggle = row as? SwitchRow<CustomSwitchCell> {
                toggle.switchValue == true ? self?.settingsViewModel.setFrameRate(to: .smooth) :
                    self?.settingsViewModel.setFrameRate(to: .normal)
            }
        }
    }
}

extension SettingsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        
        guard selectedFileURL.pathExtension == "mlmodel" else {
            let banner = NotificationBanner(title: "Failed", subtitle: "Unsupported format!", style: .danger)
            
            banner.show()
            banner.autoDismiss = true
            
            return
        }
        
        let originalName = selectedFileURL.deletingPathExtension().lastPathComponent
        
        guard let compiledModelURL = detectionViewModel.model.compileMLModel(at: selectedFileURL, originalName: originalName) else { return }
        
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationPath = directory.appendingPathComponent("\(originalName).mlmodelc")
        
        guard !FileManager.default.fileExists(atPath: destinationPath.path) else {
            let banner = NotificationBanner(title: "Oops", subtitle: "Already exists!", style: .warning)
            
            banner.show()
            banner.autoDismiss = true
            
            return
        }
        
        do {
            try FileManager.default.moveItem(at: compiledModelURL, to: destinationPath)
            
            let banner = NotificationBanner(title: "Success", subtitle: "Copied file!", style: .success)
            banner.show()
            banner.autoDismiss = true
        }
        catch {
            let banner = NotificationBanner(title: "Failed", subtitle: "Unknown error occurred!", style: .danger)
            
            banner.show()
            banner.autoDismiss = true
            
            print("Error: \(error)")
        }
    }
}
