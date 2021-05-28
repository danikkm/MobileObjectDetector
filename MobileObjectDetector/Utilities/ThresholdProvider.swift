//
//  ThresholdProvider.swift
//  MobileObjectDetector
//
//  Created by Daniel on 2021-05-16.
//

import CoreML
import Vision

/// - Tag: ThresholdProvider
/// Class providing customized thresholds for object detection model
class ThresholdProvider: ExtendedMLFeatureProvider {
    /// The actual values to provide as input
    ///
    /// Create ML Defaults are 0.45 for IOU and 0.25 for confidence.
    /// Here the IOU threshold is relaxed a little bit because there are
    /// sometimes multiple overlapping boxes per die.
    /// Technically, relaxing the IOU threshold means
    /// non-maximum-suppression (NMS) becomes stricter (fewer boxes are shown).
    /// The confidence threshold can also be relaxed slightly because
    /// objects look very consistent and are easily detected on a homogeneous
    /// background.
    
    var values = [
        "iouThreshold": MLFeatureValue(double: 0.6),
        "confidenceThreshold": MLFeatureValue(double: 0.4)
    ]
    
    /// The feature names the provider has, per the MLFeatureProvider protocol
    var featureNames: Set<String> {
        return Set(values.keys)
    }
}

extension ThresholdProvider {
    /// The actual values for the features the provider can provide
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        return values[featureName]
    }
    
    public func setFeatureValue(for feature: FeaturesName, to value: Double) {
        switch feature {
        case .iouThreshold:
            values["iouThreshold"] = MLFeatureValue(double: value)
        case .confidenceThreshold:
            values["confidenceThreshold"] = MLFeatureValue(double: value)
        }
    }
}

protocol ExtendedMLFeatureProvider: MLFeatureProvider {
    var values: [String : MLFeatureValue] { get }
    
    func setFeatureValue(for feature: FeaturesName, to value: Double)
}

enum FeaturesName: String, CustomStringConvertible {
    case iouThreshold
    case confidenceThreshold
    
    var description: String {
        switch self {
        case .iouThreshold:
            return "iouThreshold"
        case .confidenceThreshold:
            return "confidenceThreshold"
        }
    }
}
