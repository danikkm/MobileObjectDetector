//
//  SettingsViewController.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-18.
//

import UIKit
import QuickTableViewController

class SettingsViewController: QuickTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAdditionalUIElements()
        tableContents = [
            Section(title: "Camera settings", rows: [
                SwitchRow(text: "Setting 1", switchValue: true, action: { _ in }),
                SwitchRow(text: "Setting 2", switchValue: true, action: { _ in })
            ]),
            
            Section(title: "Tap Action", rows: [
                TapActionRow(text: "Tap action", action: { [weak self] _ in
                    print("Here")
                })
            ]),
        ]
        
    }
    
    private func setupAdditionalUIElements() {
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Settings"
        view.backgroundColor = .white
        navigationController?.navigationBar.tintColor = UIColor.SystemItem.cyan
        
    }
}
