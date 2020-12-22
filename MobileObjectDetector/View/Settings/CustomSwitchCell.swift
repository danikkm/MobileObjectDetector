//
//  CustomSwitchCell.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-22.
//

import QuickTableViewController

class CustomSwitchCell: SwitchCell {
    func configure(isSwitchControlEnabled: Bool) {
        switchControl.isEnabled = isSwitchControlEnabled
    }
}
