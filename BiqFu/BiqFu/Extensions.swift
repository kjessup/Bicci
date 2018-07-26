//
//  Extensions.swift
//  BiqFu
//
//  Created by Kyle Jessup on 2018-07-12.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import UIKit

extension UIView {
	@IBInspectable var cornerRadius: CGFloat {
		get { return layer.cornerRadius }
		set { layer.cornerRadius = newValue ; clipsToBounds = true }
	}
	
	@IBInspectable var borderWidth: CGFloat {
		get { return layer.borderWidth }
		set { layer.borderWidth = newValue }
	}
	
	@IBInspectable var borderColor: UIColor {
		get {
			guard let c = layer.borderColor else {
				return UIColor.clear
			}
			return UIColor(cgColor: c)
		}
		set { layer.borderColor = newValue.cgColor }
	}
}

extension Error {
	func displayForUser() {
		print("\(self)") // expand
	}
}
