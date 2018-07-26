//
//  BiqCollectionViewCell.swift
//  Bicci
//
//  Created by Kyle Jessup on 2018-07-11.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import UIKit
import SwiftCodables

extension UIColor {
	convenience init?(hex: String) {
		guard let i = Int(hex, radix: 16) else {
			return nil
		}
		self.init(red: CGFloat((i >> 16) & 0xff) / 255.0, green: CGFloat((i >> 8) & 0xff) / 255.0, blue: CGFloat(i & 0xff) / 255.0, alpha: 1.0)
	}
}

class BiqCollectionViewHeader: UICollectionReusableView {
	@IBOutlet var nameLabel: UILabel!
	
}

let expandedContentSize = CGSize(width: 340, height: 90)
let contractedContentSize = CGSize(width: 100, height: 90)

class BiqCollectionViewCell: UICollectionViewCell {
	@IBOutlet var biqName: UILabel!
	@IBOutlet var widthConstraint: NSLayoutConstraint!
	@IBOutlet var avatarScene: AvatarView!
	@IBOutlet var healthIndicator: IndicatorBar!
	@IBOutlet var happinessLabel: UILabel!
	@IBOutlet var ageLabel: UILabel!
	@IBOutlet var strLabel: UILabel!
	@IBOutlet var dexLabel: UILabel!
	@IBOutlet var intLabel: UILabel!
	@IBOutlet var chaLabel: UILabel!
	private var expanded: Bool {
		return widthConstraint.constant == expandedContentSize.width
	}
	override func prepareForReuse() {
		super.prepareForReuse()
	}
	func set(_ item: BiqCollectionItem) {
		let instance = item.instance
		biqName.text = instance.biqDeviceItem.device.name
		contentView.backgroundColor = instance.color
		if item.expanded {
			widthConstraint.constant = expandedContentSize.width
		} else {
			widthConstraint.constant = contractedContentSize.width
		}
		let avatar = instance.node
		avatarScene.setAvatar(avatar)
		healthIndicator.multiplier = CGFloat(instance.health) / 100.0
		strLabel.text = "\(instance.str)"
		dexLabel.text = "\(instance.dex)"
		intLabel.text = "\(instance.int)"
		chaLabel.text = "\(instance.cha)"
	}
	func toggleExpanded() {
		if expanded {
			widthConstraint.constant = contractedContentSize.width
		} else {
			widthConstraint.constant = expandedContentSize.width
		}
	}
}
