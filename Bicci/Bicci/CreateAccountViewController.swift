//
//  CreateAccountViewController.swift
//  Bicci
//
//  Created by Kyle Jessup on 2018-07-10.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import UIKit
import qBiqClientAPI

class CreateAccountViewController: UIViewController {
	@IBOutlet var fullNameField: UITextField!
	@IBOutlet var emailField: UITextField!
	@IBOutlet var passwordField1: UITextField!
	@IBOutlet var passwordField2: UITextField!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
	@IBAction func createAccount(_ sender: Any) {
		guard let auth = Authentication.shared,
			let name = fullNameField.text,
			let email = emailField.text,
			let password1 = passwordField1.text,
			let password2 = passwordField2.text,
			!name.isEmpty,
			!email.isEmpty,
			!password1.isEmpty,
			!password2.isEmpty else {
				return alert("Complete Fields", message: "Enter a name, an email address, and passwords to create your account.")
		}
		guard password1 == password2 else {
			return alert("Mismatching Passwords", message: "The passwords in the two fields did not match.")
		}
		auth.register(email: email, password: password1, fullName: name) {
			response in
			do {
				try response.get()
				self.main { self.performSegue(withIdentifier: "biqs", sender: self) }
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
