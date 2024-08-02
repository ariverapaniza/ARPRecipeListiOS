//
//  FavouritesPostsViewController.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 2/8/2024.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class FavouritesPostsViewController: UITableViewController {
    
    private var favouritePosts: [Post] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        fetchFavouritePosts()
    }
    
    private func setupView() {
        view.backgroundColor = .white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    private func fetchFavouritePosts() {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("Users").document(userUID)
        
        userRef.getDocument { [weak self] document, error in
            guard let document = document, document.exists,
                  let user = User(dictionary: document.data() ?? [:]) else {
                print("Error fetching user document: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            guard let savedRecipeIDs = user.savedRecipeIDs else { return }
            
            let db = Firestore.firestore()
            let postsCollection = db.collection("posts")
            
            var posts = [Post]()
            let dispatchGroup = DispatchGroup()
            
            for postID in savedRecipeIDs {
                dispatchGroup.enter()
                postsCollection.document(postID).getDocument { document, error in
                    defer { dispatchGroup.leave() }
                    
                    guard let document = document, document.exists, var post = Post(dictionary: document.data() ?? [:]) else {
                        print("Error fetching post document: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    post.id = postID
                    posts.append(post)
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self?.favouritePosts = posts
                self?.tableView.reloadData()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favouritePosts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FavouritesPostTableViewCell.identifier, for: indexPath) as? FavouritesPostTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: favouritePosts[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = favouritePosts[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let soloPostVC = storyboard.instantiateViewController(withIdentifier: "SoloPostViewController") as? SoloPostViewController else {
            print("Could not instantiate SoloPostViewController")
            return
        }
        soloPostVC.post = post
        navigationController?.pushViewController(soloPostVC, animated: true)
    }
}
