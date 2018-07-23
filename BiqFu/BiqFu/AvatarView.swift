//
//  AvatarView.swift
//  BiqFu
//
//  Created by Kyle Jessup on 2018-07-14.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import UIKit
import SceneKit

class AvatarView: UIView {
	@IBOutlet var sceneView: SCNView!
	override func awakeFromNib() {
		super.awakeFromNib()
		let scene = SCNScene()
		sceneView.scene = scene
//		let light = SCNLight()
//		light.type = .omni
//		let lightNode = SCNNode()
//		lightNode.light = light
//		lightNode.position = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
//		scene.rootNode.addChildNode(lightNode)
	}
	func setAvatar(_ node: AvatarNode) {
		guard let scene = sceneView.scene else {
			return
		}
		// remove existing node if any
		scene.rootNode.childNode(withName: "avatar", recursively: false)?.removeFromParentNode()
		node.name = "avatar"
		scene.rootNode.addChildNode(node)
	}
}
