//
//  SoloPostViewController.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 7/7/2024.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class SoloPostViewController: UIViewController {
    
    var post: Post!
    
    @IBOutlet weak var soloTitleLabel: UILabel!
    @IBOutlet weak var soloPostTextLabel: UILabel!
    @IBOutlet weak var soloPostImageView: UIImageView!
    @IBOutlet weak var favouriteSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        configureView(with: post)
        loadUserFavorites()
    }
    
    private func setupView() {
        view.backgroundColor = .white
        navigationItem.title = "Solo Post"
    }
    
    private func configureView(with post: Post) {
        soloTitleLabel.text = post.title
        soloPostTextLabel.text = post.text
        
        if let imageURL = post.imageURL {
            print("Post Image URL: \(imageURL)")
            loadImage(from: imageURL) { [weak self] image in
                if let image = image {
                    self?.soloPostImageView.image = image
                } else {
                    print("Failed to load post image from URL: \(imageURL)")
                    self?.soloPostImageView.image = UIImage(named: "noImage")
                }
            }
        } else {
            soloPostImageView.image = UIImage(named: "noImage")
        }
    }
    
    private func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error loading image from URL: \(url) - \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("Invalid image data from URL: \(url)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    private func loadUserFavorites() {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("Users").document(userUID)
        
        userRef.getDocument { [weak self] document, error in
            guard let document = document, document.exists,
                  let user = User(dictionary: document.data() ?? [:]),
                  let postID = self?.post.id else {
                return
            }
            
            self?.favouriteSwitch.isOn = user.savedRecipeIDs?.contains(postID) ?? false
        }
    }
    
    @IBAction func favouriteSwitchChanged(_ sender: UISwitch) {
        let db = Firestore.firestore()
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("Users").document(userUID)
        
        userRef.getDocument { document, error in
            guard let document = document, document.exists else {
                print("User document does not exist")
                return
            }
            
            if var user = User(dictionary: document.data() ?? [:]) {
                if sender.isOn {
                    if !(user.savedRecipeIDs?.contains(self.post.id ?? "") ?? false) {
                        user.savedRecipeIDs?.append(self.post.id ?? "")
                    }
                } else {
                    user.savedRecipeIDs?.removeAll { $0 == self.post.id }
                }
                
                userRef.setData(user.toDictionary()) { error in
                    if let error = error {
                        print("Error updating user document: \(error.localizedDescription)")
                    } else {
                        print("User document successfully updated")
                    }
                }
            }
        }
    }
}
