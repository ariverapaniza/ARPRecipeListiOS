//
//  EditProfileViewController.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 24/7/2024.
//

import UIKit
import PhotosUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import Kingfisher

protocol EditProfileViewControllerDelegate: AnyObject {
    func profileDidUpdate()
}

class EditProfileViewController: UIViewController, PHPickerViewControllerDelegate {

    weak var delegate: EditProfileViewControllerDelegate?
    var user: User?
    private var userProfPicData: Data?
    private var isLoading: Bool = false
    private var errorMessage: String = ""
    private var showError: Bool = false

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var aboutYouTextView: UITextView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var loadingView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        fetchUserData()
    }

    private func setupView() {
        view.backgroundColor = .white
        navigationItem.title = "Edit Profile"

        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectImageTapped)))
        profileImageView.isUserInteractionEnabled = true

        if let user = user {
            updateUI(with: user)
        }
    }

    private func updateUI(with user: User) {
        usernameTextField.text = user.username
        emailTextField.text = user.userEmail
        fullNameTextField.text = user.fullName
        aboutYouTextView.text = user.aboutYou

        if let userProfPicURL = user.userProfPicURL, let url = URL(string: userProfPicURL) {
            profileImageView.kf.setImage(with: url)
        } else {
            profileImageView.image = UIImage(named: "NoProfilePic")
        }
    }

    private func fetchUserData() {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("Users").document(userUID)

        userRef.getDocument { [weak self] document, error in
            guard let self = self else { return }
            if let document = document, document.exists {
                do {
                    var userData = document.data()
                    if userData?["savedRecipeIDs"] == nil {
                        userData?["savedRecipeIDs"] = []
                    }
                    self.user = try document.data(as: User.self)
                    if let user = self.user {
                        self.updateUI(with: user)
                    }
                } catch {
                    self.setError(error)
                }
            } else if let error = error {
                self.setError(error)
            }
        }
    }

    @objc private func selectImageTapped() {
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
                        self.profileImageView.image = image
                        self.userProfPicData = image.jpegData(compressionQuality: 0.8)
                    }
                }
            }
        }
    }

    @IBAction func updateProfileTapped(_ sender: UIButton) {
        updateUser()
    }

    @IBAction func cancelTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    private func updateUser() {
        isLoading = true
        loadingView.isHidden = false
        guard let userUID = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                if let userProfPicData = userProfPicData {
                    let imageReferenceID = "\(userUID)\(Date().timeIntervalSince1970)"
                    let storageRef = Storage.storage().reference().child("Profile_Images").child(imageReferenceID)
                    let _ = try await storageRef.putDataAsync(userProfPicData)
                    let downloadURL = try await storageRef.downloadURL()
                    user?.userProfPicURL = downloadURL.absoluteString
                }

                user?.username = usernameTextField.text ?? ""
                user?.userEmail = emailTextField.text ?? ""
                user?.fullName = fullNameTextField.text ?? ""
                user?.aboutYou = aboutYouTextView.text ?? ""

                try await Firestore.firestore().collection("Users").document(user?.id ?? "").setData(from: user!)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.loadingView.isHidden = true
                    self.delegate?.profileDidUpdate()
                    self.dismiss(animated: true, completion: nil)
                }
            } catch {
                setError(error)
            }
        }
    }

    func setError(_ error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.loadingView.isHidden = true
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
}
