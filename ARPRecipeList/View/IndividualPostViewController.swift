//
//  IndividualPostViewController.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 05/7/2024.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class IndividualPostViewController: UIViewController {
    
    var post: Post!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var postTextLabel: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        configureView(with: post)
        NotificationCenter.default.addObserver(self, selector: #selector(postUpdated(_:)), name: NSNotification.Name("PostUpdated"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupView() {
        view.backgroundColor = .white
        navigationItem.title = "Individual Post"
        deleteButton.tintColor = .red
        editButton.tintColor = .systemBlue
    }
    
    private func configureView(with post: Post) {
        print("Post ID: \(post.id ?? "No ID Retreived")")
        
        titleLabel.text = post.title
        postTextLabel.text = post.text
        
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
            postImageView.image = UIImage(named: "noImage")
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

    @IBAction func editPostTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "editPostSegue", sender: self)
    }
    
    @IBAction func deletePostTapped(_ sender: UIButton) {
        print("Delete button tapped")
        guard let postID = post.id else {
            print("Post ID is nil")
            return
        }
        let db = Firestore.firestore()
        
        // In here we are deleting the post document from Firestore
        deletePost(db: db, withID: postID) { [weak self] success in
            if success {
                NotificationCenter.default.post(name: NSNotification.Name("PostDeleted"), object: nil, userInfo: ["postID": postID])
                self?.navigateToPostsViewController()
            } else {
                // Show an error message to the user if the deletion of the recipe failed
                let alert = UIAlertController(title: "Error", message: "Failed to delete the post. Please try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func deletePost(db: Firestore, withID id: String, completion: @escaping (Bool) -> Void) {
        db.collection("posts").document(id).delete { error in
            if let error = error {
                print("Error deleting post: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    private func navigateToPostsViewController() {
        if let navigationController = self.navigationController {
            for viewController in navigationController.viewControllers {
                if let postsViewController = viewController as? PostsViewController {
                    navigationController.popToViewController(postsViewController, animated: true)
                    return
                }
            }
            // If not found, just pop to the root view controller (As a failsafe)
            navigationController.popToRootViewController(animated: true)
        }
    }
    
    @objc private func postUpdated(_ notification: Notification) {
        if let postID = notification.userInfo?["postID"] as? String {
            let db = Firestore.firestore()
            db.collection("posts").document(postID).getDocument { [weak self] document, error in
                guard let document = document, document.exists, var post = Post(dictionary: document.data() ?? [:]) else {
                    print("Post document not found")
                    return
                }
                post.id = postID
                self?.post = post
                self?.configureView(with: post)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editPostSegue" {
            guard let editPostVC = segue.destination as? EditPostViewController else { return }
            editPostVC.post = post
        }
    }
}
