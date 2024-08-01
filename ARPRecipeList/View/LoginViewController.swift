// LoginViewController.swift
// ARPRecipeList
//
// Created by Arturo Rivera Paniza on 23/6/2024.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.isHidden = true

        // Check login status and navigate to main screen if already logged in so the user does not have to log in every time opens the app
        if UserDefaults.standard.bool(forKey: "log_status") {
            navigateToMainScreen()
        }

        updateScrollViewContentSize()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollViewContentSize()
    }

    func updateScrollViewContentSize() {
        let contentHeight = contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        scrollView.contentSize = CGSize(width: view.frame.width, height: contentHeight)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.updateScrollViewContentSize()
        })
    }

    @IBAction func signInTapped(_ sender: UIButton) {
        loginUser()
    }

    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        resetPassword()
    }

    @IBAction func registerTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let registerVC = storyboard.instantiateViewController(withIdentifier: "RegisterViewController") as? RegisterViewController {
            registerVC.modalPresentationStyle = .fullScreen
            self.present(registerVC, animated: true, completion: nil)
        }
    }

    func loginUser() {
        guard let email = emailTextField.text, let password = passwordTextField.text else { return }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                self.setError(error)
            } else {
                print("User Found")
                UserDefaults.standard.set(true, forKey: "log_status")
                self.navigateToMainScreen()
            }
        }
    }

    func resetPassword() {
        guard let email = emailTextField.text else { return }
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            if let error = error {
                self?.setError(error)
            } else {
                print("Password reset email sent.")
            }
        }
    }

    func setError(_ error: Error) {
        errorLabel.text = error.localizedDescription
        errorLabel.isHidden = false
    }

    func navigateToMainScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainTabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? MainTabBarController {
            // Lets set the main tab bar controller as the root view controller, and the tab bar will call the item scenes
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let delegate = windowScene.delegate as? SceneDelegate {
                let window = delegate.window
                window?.rootViewController = mainTabBarController
                window?.makeKeyAndVisible()
            }
        }
    }
}
