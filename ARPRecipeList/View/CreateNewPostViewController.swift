//
//  CreateNewPostViewController.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 05/7/2024.
//


import UIKit
import PhotosUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift

class CreateNewPostViewController: UIViewController, PHPickerViewControllerDelegate {
    
    var onPost: ((Post) -> Void)?
    private var postImageData: Data?
    private var isLoading: Bool = false
    
    @IBOutlet weak var postTitleField: UITextField!
    @IBOutlet weak var postTextView: UITextView!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var loadingView: UIView!
    
    var currentUserName: String?
    var currentUserUID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        fetchCurrentUser()
    }
    
    private func setupView() {
        view.backgroundColor = .white
        loadingView.isHidden = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImageTapped(_:)))
        postImageView.addGestureRecognizer(tapGesture)
        postImageView.isUserInteractionEnabled = true
    }
    
    private func fetchCurrentUser() {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("Users").document(userUID).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                self.currentUserName = data?["username"] as? String
                self.currentUserUID = userUID
            }
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func createPostTapped() {
        createPost()
    }
    
    @IBAction func selectImageTapped(_ sender: UITapGestureRecognizer) {
        selectImage()
    }
    
    private func selectImage() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let result = results.first {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                guard let self = self else { return }
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.postImageView.image = image
                        self.postImageData = image.jpegData(compressionQuality: 0.8)
                    }
                }
            }
        }
    }
    
    private func createPost() {
        guard !isLoading else { return }
        guard let title = postTitleField.text, !title.isEmpty else {
            // Show error
            print("Error Creating Posts")
            return
        }
        guard let userName = currentUserName, let userUID = currentUserUID else {
            // Show error
            print("Error Creating Posts")
            return
        }
        
        isLoading = true
        loadingView.isHidden = false
        
        var postDict: [String: Any] = [
            "title": title,
            "text": postTextView.text,
            "userName": userName,
            "userUID": userUID,
            "timestamp": Timestamp()
        ]
        
        let db = Firestore.firestore()
        let storage = Storage.storage().reference()
        
        if let imageData = postImageData {
            let imageRef = storage.child("postImages/\(UUID().uuidString).jpg")
            imageRef.putData(imageData, metadata: nil) { metadata, error in
                guard error == nil else {
                    self.isLoading = false
                    self.loadingView.isHidden = true
                    return
                }
                imageRef.downloadURL { url, error in
                    guard let downloadURL = url else {
                        self.isLoading = false
                        self.loadingView.isHidden = true
                        return
                    }
                    postDict["imageURL"] = downloadURL.absoluteString
                    db.collection("posts").addDocument(data: postDict) { error in
                        self.isLoading = false
                        self.loadingView.isHidden = true
                        if let error = error {
                            print("Error Loading Image in Post:  \(error)")
                        } else {
                            self.onPost?(Post(dictionary: postDict)!)
                            self.navigationController?.popViewController(animated: true) // Navigate back to PostsViewController
                        }
                    }
                }
            }
        } else {
            db.collection("posts").addDocument(data: postDict) { error in
                self.isLoading = false
                self.loadingView.isHidden = true
                if let error = error {
                    // Handle error
                    print("Error Loading Posts:  \(error)")
                } else {
                    self.onPost?(Post(dictionary: postDict)!)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    @IBAction func createRecipeTapped(_ sender: UIButton) {
        createPost()
    }
}
