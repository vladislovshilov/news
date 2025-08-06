//
//  SceneDelegate.swift
//  autodoc
//
//  Created by lil angee on 28.07.25.
//

import UIKit

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private(set) var coordinator: Coordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController()
        
        coordinator = MainCoordinator(navigationController: navigationController, windows: windowScene.windows)
        coordinator?.start()
        
        self.window = window
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
