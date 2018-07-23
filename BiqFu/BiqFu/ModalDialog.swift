//
//  ModalDialog.swift
//  BiqFu
//
//  Created by Kyle Jessup on 2018-07-12.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import UIKit

class ModalDialog: UIView {
	typealias Callback = (Int, String) -> ()
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var descriptionLabel: UILabel!
	@IBOutlet var textField: UITextField!
	@IBOutlet var button0: UIButton!
	@IBOutlet var button1: UIButton!
	private var callback: Callback?
	static func run(title: String,
					description: String,
					placeholderText: String,
					button0Title: String,
					button1Title: String, callback: @escaping Callback) {
		let nib = UINib(nibName: "ModalDialog", bundle: nil)
		let me = nib.instantiate(withOwner: nil, options: nil).first! as! ModalDialog
		me.callback = callback
		me.titleLabel.text = title
		me.descriptionLabel.text = description
		me.textField.placeholder = placeholderText
		
	}
	
	@IBAction func buttonPressed(_ sender: UIButton) {
		
	}
}
