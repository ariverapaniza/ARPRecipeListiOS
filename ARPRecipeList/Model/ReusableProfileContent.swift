//
//  ReusableProfileContent.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 27/6/2024.
//

import Foundation
import UIKit
import Kingfisher

class ReusableProfileContentViewController: UIViewController {
    
    var user: User
    var savedPosts: [Post]
    
    init(user: User, savedPosts: [Post]) {
        self.user = user
        self.savedPosts = savedPosts
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = .white
    }
}
