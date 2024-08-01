//
//  MainTabBarController.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 02/7/2024.
//

import Foundation
import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Use the storyboard id to instantiate PostsViewController
        guard let postsVC = storyboard.instantiateViewController(withIdentifier: "PostsViewController") as? PostsViewController else {
            print("Could not instantiate PostsViewController")
            return
        }
        let postsNavVC = UINavigationController(rootViewController: postsVC)
        postsNavVC.tabBarItem = UITabBarItem(title: "Recipes", image: UIImage(systemName: "rectangle.portrait.on.rectangle.portrait.angled"), tag: 0)
        
        // Use the storyboard id to instantiate ProfileViewController
        guard let profileVC = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController else {
            print("Could not instantiate ProfileViewController")
            return
        }
        let profileNavVC = UINavigationController(rootViewController: profileVC)
        profileNavVC.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "gear"), tag: 1)
        
        viewControllers = [postsNavVC, profileNavVC]
        tabBar.tintColor = .green
    }
}
