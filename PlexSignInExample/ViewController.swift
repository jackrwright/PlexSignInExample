//
//  ViewController.swift
//  PlexSignInExample
//
//  Created by Jack Wright on 7/21/20.
//  Copyright © 2020 Jack Wright. All rights reserved.
//

import UIKit
import PlexAPI
import SafariServices

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var tokenLabel: UILabel!
    @IBOutlet weak var signInActivity: UIActivityIndicatorView!
    
    // MARK: - Button Handlers
    
    @IBAction func signInTapped(_ sender: UIButton) {
        
        if self.isSignedIn {
            
            let alert = UIAlertController(title: "Sign out?", message: nil, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { (action) in
                
                // sign out
                self.isSignedIn = false
            }))
            
            self.present(alert, animated: true, completion: nil)
            
        } else {
            
            if self.isSigningIn {
                
                // user wants to cancel sign-in
                
                self.timer?.invalidate()
                self.isSigningIn = false
                
                return
            }
            
            // start the sign-in process...
            
            self.isSigningIn = true
            
            PlexAPI.requestToken { (url, error) in
                
                DispatchQueue.main.async {
                    
                    if let error = error {
                        
                        let alert = UIAlertController(title: "Failed to sign in", message: error.localizedDescription, preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        
                        self.present(alert, animated: true, completion: nil)
                        
                        self.isSignedIn = false
                        self.isSigningIn = false
                        
                    } else {
                        
                        if let url = url {
                            
                            // open in a browser
                            
                            DispatchQueue.main.async {
                                
                                self.safariVC = SFSafariViewController(url: url)
                                
                                self.present(self.safariVC!, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - View controller life-cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Initially set the UI to indicate sign-in status based on whether there is a token saved.
        self.isSignedIn = PlexAPI.isSignedIn
        
        if isSignedIn {
            
            // verify that the current token is valid and update the UI accordingly
            PlexAPI.getToken { (token, error) in
                
                DispatchQueue.main.async {
                    
                    self.isSignedIn = token != nil ? true : false
                    
                    self.tokenLabel.text = token
                }
            }
        }
        
        // Register for a notification of when we received an auth token
        Foundation.NotificationCenter.default.addObserver(self,
                                                          selector: #selector(didSignIn(_:)),
                                                          name: NSNotification.Name(rawValue: PlexAPI.signedIntoPlex),
                                                          object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        if isSigningIn {
            
            self.pollForAuthToken()
        }
    }
    
    // MARK: - Private (methods)
    
    /// This method is called in response to the PlexAPI.signedIntoPlex notification
    /// - Parameter notification: not used
    @objc private func didSignIn(_ notification: Notification) {
        
        DispatchQueue.main.async {
            
            self.isSignedIn = true
            
            self.safariVC?.dismiss(animated: true, completion: nil)
            
            self.tokenLabel.text = PlexAPI.savedToken ?? "No Token!"
        }
    }
    
    
    // MARK: - Private (properties)
    
    private var isSignedIn: Bool {
        
        get {
            PlexAPI.isSignedIn
        }
        
        set {
            // Update the UI when the signed-in status changes
            
            DispatchQueue.main.async {
                
                if newValue == false {
                    
                    // signed out
                    
                    self.signInButton.setTitle("Sign in", for: .normal)
                    
                    self.tokenLabel.text = ""
                    
                    PlexAPI.signOut()
                    
                } else {
                    
                    // signed into plex.tv (we have a valid token)
                    
                    self.isSigningIn = false
                    
                    self.signInButton.setTitle("Sign out", for: .normal)
                }
            }
        }
    }
    
    private var isSigningIn: Bool = false {
        didSet {
            if isSigningIn {
                self.signInButton.setTitle("Cancel", for: .normal)
                self.signInActivity.startAnimating()
            } else {
                self.timer?.invalidate()
                self.signInActivity.stopAnimating()
                self.signInButton.setTitle("Sign in", for: .normal)
            }
        }
    }
    
    private var timer: Timer?
    
    
    /// Poll periodically for a valid auth token to show up
    private func pollForAuthToken() {
        
        timer =  Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
            
            PlexAPI.checkForAuthToken()
        }
    }
    
    private var safariVC: SFSafariViewController? = nil
    
}

