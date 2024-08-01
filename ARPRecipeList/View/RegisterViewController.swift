//
//  RegisterViewController.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 23/6/2024.
//

import UIKit
import PhotosUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var aboutYouTextField: UITextView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    
    var userProfPicData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.isHidden = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped(_:)))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @IBAction func signUpTapped(_ sender: UIButton) {
        registerUser()
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func profileImageTapped(_ sender: UITapGestureRecognizer) {
        showPicPicker()
    }
    
    func showPicPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func registerUser() {
        guard let email = emailTextField.text, let password = passwordTextField.text else { return }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                self.setError(error)
            } else {
                print("User Created")
                self.errorLabel.text = "User Created"
                self.errorLabel.isHidden = false
                // Save the additional user information into Firestore
                if let imageData = self.userProfPicData {
                    self.uploadProfileImage(imageData: imageData) { (url: URL?) in
                        self.saveUserInfo(profileImageUrl: url) {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                } else {
                    // Use default image in case no image provided buy the en user
                    if let defaultImage = UIImage(named: "NoProfilePic"), let defaultImageData = defaultImage.jpegData(compressionQuality: 0.8) {
                        self.uploadProfileImage(imageData: defaultImageData) { (url: URL?) in
                            self.saveUserInfo(profileImageUrl: url) {
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    } else {
                        self.saveUserInfo(profileImageUrl: nil) {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func uploadProfileImage(imageData: Data, completion: @escaping (URL?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        let storageRef = Storage.storage().reference().child("profile_images").child("\(uid).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Failed to upload profile image: \(error)")
                completion(nil)
                return
            }
            
            storageRef.downloadURL { (url: URL?, error: Error?) in
                if let error = error {
                    print("Failed to get download URL: \(error)")
                    completion(nil)
                    return
                }
                completion(url)
            }
        }
    }
    
    func saveUserInfo(profileImageUrl: URL?, completion: @escaping () -> Void) {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        let user = User(
            id: userUID,
            username: usernameTextField.text ?? "",
            fullName: fullNameTextField.text ?? "",
            aboutYou: aboutYouTextField.text ?? "",
            userUID: userUID,
            userEmail: emailTextField.text ?? "",
            userProfPicURL: profileImageUrl?.absoluteString
        )
        
        do {
            try Firestore.firestore().collection("Users").document(userUID).setData(from: user)
            print("User information saved")
            completion()
        } catch let error {
            setError(error)
        }
    }
    
    func setError(_ error: Error) {
        errorLabel.text = error.localizedDescription
        errorLabel.isHidden = false
    }
}

extension RegisterViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let result = results.first {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                guard let self = self else { return }
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.profileImageView.image = image
                        self.userProfPicData = image.jpegData(compressionQuality: 0.8)
                    }
                }
            }
        }
    }
}
