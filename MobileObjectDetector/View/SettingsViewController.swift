//
//  SettingsViewController.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-18.
//

import UIKit
import QuickTableViewController
import MobileCoreServices
import CoreML
import RxSwift
import RxCocoa
import RxDataSources

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
                SwitchRow(text: "60 frames per second", switchValue: settingsViewModel.frameRateSwitch, action: self.didToggleFrameRateSection())
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
            if let toggle = row as? SwitchRow {
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
        
        guard let compiledModelURL = compileMLModel(at: selectedFileURL) else { return }
        print(compiledModelURL)
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sandboxFileURL = dir.appendingPathComponent(compiledModelURL.lastPathComponent)
        print(sandboxFileURL.path, sandboxFileURL)
        if FileManager.default.fileExists(atPath: sandboxFileURL.path) {
            print("Already exists! Do nothing")
        }
        else {
            
            do {
                try FileManager.default.copyItem(at: compiledModelURL, to: sandboxFileURL)
                
                print("Copied file!")
            }
            catch {
                print("Error: \(error)")
            }
        }
    }
    
    private func compileMLModel(at selectedFileURL: URL) -> URL? {
        do {
            return try MLModel.compileModel(at: selectedFileURL)
        } catch {
            print("Compile error")
            return nil
        }
    }
}
