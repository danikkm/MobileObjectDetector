//
//  Double+Extension.swift
//  MobileObjectDetector
//
//  Created by Daniel on 2021-05-19.
//

import Foundation

extension Double {
    func round(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
