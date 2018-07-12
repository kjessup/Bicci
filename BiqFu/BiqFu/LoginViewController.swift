//
//  LoginViewController.swift
//  Bicci
//
//  Created by Kyle Jessup on 2018-07-10.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import UIKit
import qBiqClientAPI

class LoginViewController: UIViewController {
	@IBOutlet var emailField: UITextField!
	@IBOutlet var passwordField: UITextField!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	@IBAction func unwindToLogin(segue:UIStoryboardSegue) {
		
	}

	@IBAction func login(_ sender: Any) {
		guard let auth = Authentication.shared,
			let email = emailField.text,
			let password = passwordField.text,
			!email.isEmpty,
			!password.isEmpty else {
				return alert("Complete Fields", message: "Enter an email address and password to sign in.")
		}
		auth.login(email: email, password: password) {
			response in
			do {
				try response.get()
				self.main { self.performSegue(withIdentifier: "unwindOpening", sender: self) }
			} catch {
				self.alert(error)
			}
		}
	}
	/*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
