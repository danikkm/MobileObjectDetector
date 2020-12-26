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

class SettingsViewController: QuickTableViewController {
    
    private var mlModelsViewModel: MLModelsViewModelProtocol!
    private var settingsViewModel: SettingsViewModelProtocol!
    private var detectionViewModel: DetectionViewModelProtocol!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainUIElements()
        setupAdditionalUIElements()
        setupBindings()
    }
    
    func prepare(detectionViewModel: DetectionViewModelProtocol, mlModelsViewModel: MLModelsViewModelProtocol, settingsViewModel: SettingsViewModelProtocol) {
        self.detectionViewModel = detectionViewModel
        self.mlModelsViewModel = mlModelsViewModel
        self.settingsViewModel = settingsViewModel
    }
    
    private func setupMainUIElements() {
        tableContents = [
            Section(title: "Camera settings", rows: [
                SwitchRow<CustomSwitchCell>(text: "60 frames per second", switchValue: settingsViewModel.frameRateSwitch, action: self.didToggleFrameRateSection())
            ]),
            
            Section(title: "Import models", rows: [
                TapActionRow(text: "Select ML model", action: { [weak self] _ in
                    guard let self = self else { return }
                    
                    // TODO: fix errors/warnings when trying to import
                    // TODO: add only mlmodel extension
                    let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
                    documentPicker.delegate = self
                    documentPicker.allowsMultipleSelection = false
                    self.present(documentPicker, animated: true, completion: nil)
                })
            ]),
            Section(title: "", rows: [
                TapActionRow(text: "Open ML model selection", action: { [weak self] _ in
                    guard let self = self else { return }
                    let mlModelSelectionVC = MLModelSelectionViewController()
                    mlModelSelectionVC.prepare(viewModel: self.mlModelsViewModel)
                    self.navigationController?.pushViewController(mlModelSelectionVC, animated: true)
                })
            ])
            
        ]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        detectionViewModel.frameRateObservable
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] frameRate in
                self?.detectionViewModel.changeFrameRate(to: frameRate)
            }).disposed(by: disposeBag)
    }
}

// MARK: - Actions
extension SettingsViewController {
    private func didToggleFrameRateSection() -> (Row) -> Void {
        return { [weak self] row in
            if let toggle = row as? SwitchRow<CustomSwitchCell> {
                if toggle.switchValue == true {
                    self?.detectionViewModel.frameRateRelay.accept(60.0)
                    self?.settingsViewModel.frameRateSwitchRelay.accept(.smooth)
                } else {
                    self?.detectionViewModel.frameRateRelay.accept(30.0)
                    self?.settingsViewModel.frameRateSwitchRelay.accept(.normal)
                }
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
        
        guard let compiledModelURL = mlModelsViewModel.compileMLModel(at: selectedFileURL, originalName: originalName) else { return }
        
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
