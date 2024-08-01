//
//  PostsViewController.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 08/7/2024.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class PostsViewController: UIViewController {
    
    private var recentPosts: [Post] = []

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        fetchPosts()
        
        NotificationCenter.default.addObserver(self, selector: #selector(postDeleted(_:)), name: NSNotification.Name("PostDeleted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postUpdated(_:)), name: NSNotification.Name("PostUpdated"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupView() {
        view.backgroundColor = .white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    @IBAction func createNewPostTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showCreateNewPost", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCreateNewPost" {
            if let createPostVC = segue.destination as? CreateNewPostViewController {
                createPostVC.onPost = { post in
                    self.recentPosts.insert(post, at: 0)
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func fetchPosts() {
        let db = Firestore.firestore()
        db.collection("posts").order(by: "timestamp", descending: true).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            self.recentPosts = documents.compactMap { document in
                var post = Post(dictionary: document.data())
                post?.id = document.documentID
                return post
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    @objc private func postDeleted(_ notification: Notification) {
        if let postID = notification.userInfo?["postID"] as? String {
            if let index = recentPosts.firstIndex(where: { $0.id == postID }) {
                recentPosts.remove(at: index)
                tableView.reloadData()
            }
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
                if let index = self?.recentPosts.firstIndex(where: { $0.id == postID }) {
                    self?.recentPosts[index] = post
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                }
            }
        }
    }
}

extension PostsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.identifier, for: indexPath) as? PostTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: recentPosts[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = recentPosts[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let currentUserUID = Auth.auth().currentUser?.uid
        
        if post.userUID == currentUserUID {
            guard let individualPostVC = storyboard.instantiateViewController(withIdentifier: "IndividualPostViewController") as? IndividualPostViewController else {
                print("Could not instantiate IndividualPostViewController")
                return
            } // Comment
            individualPostVC.post = post
            navigationController?.pushViewController(individualPostVC, animated: true)
        } else {
            guard let soloPostVC = storyboard.instantiateViewController(withIdentifier: "SoloPostViewController") as? SoloPostViewController else {
                print("Could not instantiate SoloPostViewController")
                return
                // Comment
            }
            soloPostVC.post = post
            navigationController?.pushViewController(soloPostVC, animated: true)
        }
    }
}
