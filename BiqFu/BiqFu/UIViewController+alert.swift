//
//  UIViewController+alert.swift
//  Bicci
//
//  Created by Kyle Jessup on 2018-07-11.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import UIKit
import qBiqClientAPI

extension UIViewController {
	
	func main(_ closure: @escaping () -> ()) {
		DispatchQueue.main.async(execute: closure)
	}
	
	func alert(_ error: Error) {
		switch error {
		case let error as Authentication.Error:
			alert("Error", message: error.description)
		case let error as APIRequest.Error:
			alert("Error", message: "Status code: \(error.status). \(error.description)")
		default:
			print("Generic error \(type(of: error))")
			alert("Error", message: "\(error.localizedDescription)")
		}
	}
	
	func alert(_ title: String, message: String) {
		DispatchQueue.main.async {
			let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
			let action = UIAlertAction(title: "OK", style: .default) {
				(a:UIAlertAction) -> Void in
			}
			alert.addAction(action)
			self.present(alert, animated: true) { }
		}
	}
	
	func alert(_ title: String, message: String, cancel: (() -> ())? = nil, okay: @escaping () -> ()) {
		DispatchQueue.main.async {
			let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
			let okAction = UIAlertAction(title: "OK", style: .default) {
				(a:UIAlertAction) -> Void in
				okay()
			}
			alert.addAction(okAction)
			if let cancel = cancel {
				let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
					(a:UIAlertAction) -> Void in
					cancel()
				}
				alert.addAction(cancelAction)
			}
			self.present(alert, animated: true) { }
		}
	}
	
	private func alert(_ title: String, value: String, placeholder: String, message: String, action: @escaping(String) -> (), cancel: @escaping() -> ()) {
		DispatchQueue.main.async {
			let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
			
			alert.addTextField {
				textField in
				textField.keyboardAppearance = .dark
				textField.keyboardType = .default
				textField.autocorrectionType = .default
				textField.text = value
				textField.placeholder = placeholder
				textField.clearButtonMode = .whileEditing
			}
			
			let okAction = UIAlertAction(title: "OK", style: .default) {
				(a:UIAlertAction) -> Void in
				action((alert.textFields?[0].text)!)
			}
			
			let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
				(a:UIAlertAction) -> Void in
				cancel()
			}
			
			alert.addAction(okAction)
			alert.addAction(cancelAction)
			
			self.present(alert, animated: true) { }
		}
	}
	
	
	func alertNetworkError() {
		alert("Network Error", message: "There was a network error and the app did not function as expected. Please check your network connectivity and try again.")
	}
}
