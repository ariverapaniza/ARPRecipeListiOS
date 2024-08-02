//
//  EditPostViewController.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 14/7/2024.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

class EditPostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var postTextView: UITextView!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var updateButton: UIButton!
    
    var errorMessage: String = ""
    var showError: Bool = false
    var isLoading: Bool = false
    var favourite: Bool = false
    
    var post: Post!
    var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        guard let post = post else {
            print("Error: Post is nil")
            return
        }
        configureView(with: post)
        setupImageViewTap()
    }
    
    private func setupView() {
        view.backgroundColor = .white
        navigationItem.title = "Edit Post"
        updateButton.tintColor = .systemBlue
        imagePicker.delegate = self
    }
    
    private func configureView(with post: Post) {
        do {
            titleTextField.text = post.title
            postTextView.text = post.text
            favourite = post.favourite
            
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
        } catch {
            setError(error)
            print("Error: \(error)")
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
    
    private func setupImageViewTap() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped))
        postImageView.isUserInteractionEnabled = true
        postImageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func imageViewTapped() {
        let alert = UIAlertController(title: "Select Image", message: "Choose an image from your library", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.openPhotoLibrary()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private func openPhotoLibrary() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let selectedImage = info[.originalImage] as? UIImage {
            postImageView.image = selectedImage
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    @IBAction func updatePostTapped(_ sender: UIButton) {
        guard let postID = post.id,
              let updatedTitle = titleTextField.text,
              let updatedText = postTextView.text else {
            print("Missing post details or post ID")
            return
        }
        
        let db = Firestore.firestore()
        var updatedData: [String: Any] = [
            "title": updatedTitle,
            "text": updatedText,
            "timestamp": Timestamp(date: Date())
        ]
        
        if let updatedImage = postImageView.image, let imageData = updatedImage.jpegData(compressionQuality: 0.8) {
            let storageRef = Storage.storage().reference().child("post_images/\(postID).jpg")
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    return
                }
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                        return
                    }
                    if let imageURL = url?.absoluteString {
                        updatedData["imageURL"] = imageURL
                        self.updatePostData(db: db, postID: postID, data: updatedData)
                    }
                }
            }
        } else {
            updatePostData(db: db, postID: postID, data: updatedData)
        }
    }
    
    private func updatePostData(db: Firestore, postID: String, data: [String: Any]) {
        db.collection("posts").document(postID).updateData(data) { error in
            if let error = error {
                print("Error updating post: \(error.localizedDescription)")
                return
            }
            NotificationCenter.default.post(name: NSNotification.Name("PostUpdated"), object: nil, userInfo: ["postID": postID])
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func setError(_ error: Error) {
        isLoading = false
        errorMessage = error.localizedDescription
        showError = true
    }
}
