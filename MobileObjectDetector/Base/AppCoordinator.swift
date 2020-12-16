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
        let viewController = ObjectRecognitionViewController.instantiate(viewModel: DetectionViewModel())
        let navigationController = UINavigationController(rootViewController: viewController)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}
