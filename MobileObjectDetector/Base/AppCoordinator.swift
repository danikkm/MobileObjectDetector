//
//  AppCoordinator.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 12/16/20.
//

import UIKit

class AppCoordinator {
    private let window: UIWindow?
    
    init (window: UIWindow) {
        self.window = window
    }
    
    func start() {
        let viewController = ObjectRecognitionViewController.instantiate(detectionViewModel: DetectionViewModel(), mlModelsViewModel: MLModelsViewModel())
        let navigationController = UINavigationController(rootViewController: viewController)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}
