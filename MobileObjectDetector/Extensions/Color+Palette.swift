//
//Color+Palette.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 2020-12-17.
//

import Foundation
import UIKit

extension UIColor {
    struct Button {
        static let stop = UIColor(red: 0.9176368713, green: 0.5647383332, blue: 0.5528833866, alpha: 1)
        static let start = UIColor.white
    }
    
    struct SystemItem {
        static let cyan = UIColor(red: 0.4525331855, green: 0.8567983508, blue: 1, alpha: 1)
        static let white = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
    }
}

extension CGColor {
    struct SystemItem {
        static let cyan = CGColor(red: 0.4525331855, green: 0.8567983508, blue: 1, alpha: 1)
        static let white = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
    }
}


