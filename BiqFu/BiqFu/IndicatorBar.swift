//
//  IndicatorBar.swift
//  BiqFu
//
//  Created by Kyle Jessup on 2018-07-23.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import UIKit

class IndicatorBar: UIView {
	@IBOutlet var barWidth: NSLayoutConstraint!
	@IBOutlet var barView: UIView!
	var multiplier: CGFloat {
		set {
			barWidth.constant = bounds.width * newValue
			layoutIfNeeded()
		}
		get {
			return bounds.width / barWidth.constant
		}
	}
}
