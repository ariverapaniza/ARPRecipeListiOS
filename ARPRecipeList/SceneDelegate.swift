//
//  SceneDelegate.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 23/6/2024.
//

import UIKit
import Firebase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // Check login status and set initial view controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if UserDefaults.standard.bool(forKey: "log_status") {
            let mainTabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
            window.rootViewController = mainTabBarController
        } else {
            let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            window.rootViewController = loginViewController
        }

        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
}
