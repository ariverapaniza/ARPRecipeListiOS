//
//  ProfileViewController.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 2/7/2024.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage

class ProfileViewController: UIViewController, EditProfileViewControllerDelegate {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var aboutYouLabel: UILabel!

    var logStatus: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "log_status")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "log_status")
        }
    }
    
    var myProfile: User?
    var errorMessage: String = ""
    var showError: Bool = false
    var isLoading: Bool = false
    var savedPosts: [Post] = []
    var showEditProfile: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        fetchUserData()
        printUserUID()
        setupProfileContent()
    }

    private func setupView() {
        view.backgroundColor = .white
        navigationItem.title = "Profile"
    }

    private func printUserUID() {
        if let userUID = Auth.auth().currentUser?.uid {
            print("User UID: \(userUID)")
        } else {
            print("No user is currently logged in.")
        }
    }

    @objc private func logOutUser() {
        try? Auth.auth().signOut()
        logStatus = false
        print("User Logged Out")
        UserDefaults.standard.set(false, forKey: "log_status")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
            loginViewController.modalPresentationStyle = .fullScreen
            self.present(loginViewController, animated: true, completion: nil)
        }
    }

    @objc private func deleteAccount() {
        isLoading = true

        Task {
            do {
                guard let userUID = Auth.auth().currentUser?.uid else { return }
                let reference = Storage.storage().reference().child("Profile_Images").child(userUID)
                try await reference.delete()
                try await Firestore.firestore().collection("Users").document(userUID).delete()
                try await Auth.auth().currentUser?.delete()
                logStatus = false
                UserDefaults.standard.set(false, forKey: "log_status")
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                    loginViewController.modalPresentationStyle = .fullScreen
                    self.present(loginViewController, animated: true, completion: nil)
                }
            } catch {
                setError(error)
            }
        }
    }

    func fetchUserData() {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        print("Function fetchUserData called")
        Firestore.firestore().collection("Users").document(userUID).getDocument { (document, error) in
            if let document = document, document.exists {
                do {
                    var userData = document.data()
                    if userData?["savedRecipeIDs"] == nil {
                        userData?["savedRecipeIDs"] = []
                    }
                    self.myProfile = try document.data(as: User.self)
                    self.setupProfileContent()
                } catch {
                    self.setError(error)
                    print("Error: \(error)")
                }
            }
        }
    }

    private func setupProfileContent() {
        guard let myProfile = myProfile else { return }
        print("Function setupProfileContent called")
        usernameLabel.text = myProfile.username
        print("Username: \(myProfile.username)")
        emailLabel.text = myProfile.userEmail
        print("Email: \(myProfile.userEmail)")
        fullNameLabel.text = myProfile.fullName
        print("Full Name: \(myProfile.fullName)")
        aboutYouLabel.text = myProfile.aboutYou
        print("About You: \(myProfile.aboutYou)")

        if let urlString = myProfile.userProfPicURL, let url = URL(string: urlString) {
            loadImage(from: url) { image in
                self.profileImageView.image = image
                //print("Profile Picture: \(myProfile.userProfPicURL)")
            }
        }
    }

    private func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }

    @IBAction func logOutTapped(_ sender: UIButton) {
        logOutUser()
    }
    
    @IBAction func editProfileTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "editProfileSegue", sender: self)
    }
    
    @IBAction func favouritesTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showFavouritesSegue", sender: self)
    }

    func setError(_ error: Error) {
        isLoading = false
        errorMessage = error.localizedDescription
        showError = true
    }

    func profileDidUpdate() {
        fetchUserData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editProfileSegue" {
            guard let editProfileVC = segue.destination as? EditProfileViewController else { return }
            editProfileVC.user = myProfile
            editProfileVC.delegate = self
            editProfileVC.modalPresentationStyle = .fullScreen
        } else if segue.identifier == "showFavouritesSegue" {
            guard let favouritesVC = segue.destination as? FavouritesPostsViewController else { return }
        }
    }
}
