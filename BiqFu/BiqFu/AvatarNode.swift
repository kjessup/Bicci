//
//  AvatarNode.swift
//  BiqFu
//
//  Created by Kyle Jessup on 2018-07-20.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import Foundation
import SceneKit

fileprivate func standardNode(named name: String) -> SCNNode? {
	if let scene = SCNScene(named: "art.scnassets/\(name).scn"),
		let node = scene.rootNode.childNode(withName: name, recursively: false) {
		let scale = Float(0.01)
		node.scale = SCNVector3(x: scale, y: scale, z: scale)
		return node
	}
	return nil
}

enum AvatarNodeType: String, CaseIterable {
	case cat = "cat1", fox = "fox1", bunny = "bunny1"//, dog = "dog1", //, elephant//, frog
	init() {
		let rnd = Int.random(in: 0..<AvatarNodeType.allCases.count)
		self = AvatarNodeType.allCases[rnd]
	}
//	func node(id: String? = nil) -> AvatarNode {
//		let name = rawValue
//		let parent = AvatarNode()
//		if let node = standardNode(named: name) {
//			if let id = id {
//				addName(id, to: parent, avatarDepth: boxDepth(node.boundingBox, scale: node.scale.x))
//			}
//			parent.addChildNode(node)
//			parent.finishCreate()
//		}
//		parent.nodeType = self
//		return parent
//	}
}

fileprivate let mouthNodeName = "mouth"
let healthMaximum = 100.0
let healthMinimum = 0.0

class AvatarNode: SCNNode {
	let biq: BiqInstance
	var mouthNode: SCNNode? {
		return childNode(withName: mouthNodeName, recursively: true)
	}
	init(biq: BiqInstance) {
		self.biq = biq
		super.init()
		if let node = standardNode(named: biq.avatarType.rawValue) {
			addChildNode(node)
			finishCreate()
		}
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init?(coder aDecoder: NSCoder) not implimented")
	}
	func finishCreate() {
		setMouth()
	}
	private func setMouth() {
		let mouthName: String
		switch biq.health {
		case 75...100:
			mouthName = "mouth1-1"
		case 50..<75:
			mouthName = "mouth1-2"
		case 25..<50:
			mouthName = "mouth1-3"
		default:
			mouthName = "mouth1-4"
		}
		guard let node = standardNode(named: mouthName),
			let mouth = mouthNode else {
			return
		}
		let scale = CGFloat(1.0)
		node.scale = SCNVector3(scale, scale, scale)
		mouth.addChildNode(node)
	}
	func addName(_ name: String, to parent: SCNNode, avatarDepth: Float) {
		let text = SCNText(string: name.split(separator: "-").last!, extrusionDepth: 0.5)
		text.font = UIFont.systemFont(ofSize: 12)
		text.firstMaterial?.diffuse.contents = UIColor.orange
		text.firstMaterial?.specular.contents = UIColor.orange
		let textNode = SCNNode(geometry: text)
		parent.addChildNode(textNode)
		let scale = Float(0.001)
		textNode.scale = SCNVector3(scale, scale, scale)
		let box = textNode.boundingBox
		let width = boxWidth(box, scale: scale)
		let depth = avatarDepth + 0.01
		textNode.runAction(SCNAction.sequence([
			.rotateBy(x: CGFloat(.pi * -0.5), y: 0, z: 0, duration: 0.0),
			.moveBy(x: -CGFloat(width / 2), y: 0, z: CGFloat(depth), duration: 0.0)
			]))
	}
}
