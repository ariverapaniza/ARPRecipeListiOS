//
//  PostTableViewCell.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 1/7/2024.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift

class PostTableViewCell: UITableViewCell {
    
    static let identifier = "PostTableViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var postTextLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var postImageView: UIImageView!
    
    func configure(with post: Post) {
        print("Post ID: \(post.id ?? "No ID")")
        
        titleLabel.text = post.title
        postTextLabel.text = post.text
        usernameLabel.text = post.userName
        dateLabel.text = DateFormatter.localizedString(from: post.publishedDate, dateStyle: .short, timeStyle: .short)
        
        fetchUserProfileImage(userUID: post.userUID)
        
        if let imageURL = post.imageURL {
            print("Post Image URL: \(imageURL)")
            loadImage(from: imageURL) { [weak self] image in
                if let image = image {
                    self?.postImageView.image = image
                } else {
                    print("Failed to load post image from URL: \(imageURL)")
                    self?.postImageView.image = UIImage(named: "noImage")
                }
            }
        } else {
            postImageView.isHidden = true
        }
    }

    
    private func fetchUserProfileImage(userUID: String) {
        let db = Firestore.firestore()
        db.collection("Users").document(userUID).getDocument { [weak self] document, error in
            if let document = document, document.exists, let data = document.data() {
                if let profileImageURLString = data["userProfPicURL"] as? String, let profileImageURL = URL(string: profileImageURLString) {
                    self?.loadImage(from: profileImageURL) { image in
                        if let image = image {
                            self?.profileImageView.image = image
                        } else {
                            print("Failed to load profile image from URL: \(profileImageURL)")
                        }
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
