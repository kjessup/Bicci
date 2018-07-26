//
//  TameBiqViewController.swift
//  BiqFu
//
//  Created by Kyle Jessup on 2018-07-24.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import UIKit

class TamedBiqViewController: UIViewController {
	@IBOutlet var avatarView: AvatarView!
	@IBOutlet var strLabel: UILabel!
	@IBOutlet var dexLabel: UILabel!
	@IBOutlet var intLabel: UILabel!
	@IBOutlet var chaLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
		let appState = AppDelegate.state!
		let avatar = appState.newBiq!
		let instance = avatar.biqInstance
		appState.visibleBiqs = appState.visibleBiqs.filter { $0.id != instance.id }
		appState.myBiqs.append(instance)
		avatar.reload()
		
		strLabel.text = "\(instance.str)"
		dexLabel.text = "\(instance.dex)"
		intLabel.text = "\(instance.int)"
		chaLabel.text = "\(instance.cha)"
		
		avatarView.setAvatar(instance.node)
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}
}
