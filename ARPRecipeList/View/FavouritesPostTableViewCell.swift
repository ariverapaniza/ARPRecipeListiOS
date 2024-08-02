//
//  FavouritesPostTableViewCell.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 2/8/2024.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift

class FavouritesPostTableViewCell: UITableViewCell {
    
    static let identifier = "FavouritesPostTableViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var postTextLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var favouriteSwitch: UISwitch!
    
    var post: Post?
    
    func configure(with post: Post) {
        self.post = post
        titleLabel.text = post.title
        postTextLabel.text = post.text
        usernameLabel.text = post.userName
        dateLabel.text = DateFormatter.localizedString(from: post.publishedDate, dateStyle: .short, timeStyle: .short)
        
        fetchUserProfileImage(userUID: post.userUID)
        
        if let imageURL = post.imageURL {
            loadImage(from: imageURL) { [weak self] image in
                self?.postImageView.image = image ?? UIImage(named: "noImage")
            }
        } else {
            postImageView.isHidden = true
        }
        
        updateFavouriteSwitch()
    }
    
    private func updateFavouriteSwitch() {
        guard let post = post, let userUID = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("Users").document(userUID)
        
        userRef.getDocument { [weak self] document, error in
            guard let self = self, let document = document, document.exists,
                  let user = User(dictionary: document.data() ?? [:]) else {
                return
            }
            
            self.favouriteSwitch.isOn = user.savedRecipeIDs?.contains(post.id ?? "") ?? false
        }
    }
    
    @IBAction func favouriteSwitchChanged(_ sender: UISwitch) {
        guard let post = post, let userUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(userUID)
        
        userRef.getDocument { document, error in
            guard let document = document, document.exists else {
                print("User document does not exist")
                return
            }
            
            if var user = User(dictionary: document.data() ?? [:]) {
                if sender.isOn {
                    if !(user.savedRecipeIDs?.contains(post.id ?? "") ?? false) {
                        user.savedRecipeIDs?.append(post.id ?? "")
                    }
                } else {
                    user.savedRecipeIDs?.removeAll { $0 == post.id }
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
    
    private func fetchUserProfileImage(userUID: String) {
        let db = Firestore.firestore()
        db.collection("Users").document(userUID).getDocument { [weak self] document, error in
            if let document = document, document.exists, let data = document.data() {
                if let profileImageURLString = data["userProfPicURL"] as? String, let profileImageURL = URL(string: profileImageURLString) {
                    self?.loadImage(from: profileImageURL) { image in
                        self?.profileImageView.image = image
                    }
                }
            } else {
                print("User document does not exist")
            }
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
}
