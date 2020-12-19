//
//  SettingsViewController.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-18.
//

import UIKit
import QuickTableViewController
import MobileCoreServices


class SettingsViewController: QuickTableViewController {
    
    var mlModelsViewModel: MLModelsViewModelProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAdditionalUIElements()
        prepare()
        tableContents = [
            Section(title: "Camera settings", rows: [
                SwitchRow(text: "Setting 1", switchValue: true, action: { _ in }),
                SwitchRow(text: "Setting 2", switchValue: true, action: { _ in })
            ]),
            
            Section(title: "Tap Action", rows: [
                TapActionRow(text: "Select ML model", action: { [weak self] _ in
                    guard let self = self else { return }
//                    let documentPicker = UIDocumentPickerViewController(documentTypes: ["mlmodel"], in: .import)
                    let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
                    documentPicker.delegate = self
                    documentPicker.allowsMultipleSelection = false
                    self.present(documentPicker, animated: true, completion: nil)
                }),
                TapActionRow(text: "Load all models", action: { [weak self] _ in
                    guard let self = self else { return }
                    self.mlModelsViewModel?.test()
                })
            ]),
        ]
        
    }
    
    func prepare() {
        self.mlModelsViewModel = MLModelsViewModel()
    }
    
    private func setupAdditionalUIElements() {
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Settings"
        view.backgroundColor = .white
        navigationController?.navigationBar.tintColor = UIColor.SystemItem.cyan
        
    }
}

extension SettingsViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        guard let selectedFileURL = urls.first else {
            return
        }
            
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sandboxFileURL = dir.appendingPathComponent(selectedFileURL.lastPathComponent)

        if FileManager.default.fileExists(atPath: sandboxFileURL.path) {
            print("Already exists! Do nothing")
        }
        else {

            do {
                try FileManager.default.copyItem(at: selectedFileURL, to: sandboxFileURL)

                print("Copied file!")
            }
            catch {
                print("Error: \(error)")
            }
        }
    }
}
