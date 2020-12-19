//
//  SceneDelegate.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 12/16/20.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {        
        guard let scene = (scene as? UIWindowScene) else { return }
        
        self.window = UIWindow(windowScene: scene)
        appCoordinator = AppCoordinator(window: self.window ?? UIWindow(frame: UIScreen.main.bounds))
        appCoordinator?.start()
    }
}

