//
//  AvatarNode.swift
//  BiqFu
//
//  Created by Kyle Jessup on 2018-07-20.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import Foundation
import SceneKit

fileprivate let mouthNodeName = "mouth"
let healthMaximum = 100.0
let healthMinimum = 0.0

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
	case unknown
	var node: SCNNode? {
		if self == .unknown {
			let text = SCNText(string: "?", extrusionDepth: 0.5)
			text.font = UIFont.systemFont(ofSize: 12)
			text.firstMaterial?.diffuse.contents = UIColor.red
			text.firstMaterial?.specular.contents = UIColor.orange
			let textNode = SCNNode(geometry: text)
			let scale = Float(0.005)
			textNode.scale = SCNVector3(scale, scale, scale)
			textNode.name = "question mark"
			textNode.position = SCNVector3(-0.014, 0, -0.001)
			return textNode
		}
		return standardNode(named: rawValue)
	}
	static var random: AvatarNodeType {
		let cases = allCases.filter { $0 != .unknown }
		let rnd = Int.random(in: 0..<cases.count)
		return cases[rnd]
	}
	init() {
//		let rnd = Int.random(in: 0..<AvatarNodeType.allCases.count)
//		self = AvatarNodeType.allCases[rnd]
		self = .unknown
	}
}

class AvatarNode: SCNNode {
	let biqInstance: BiqInstance
	var mouthNode: SCNNode? {
		return childNode(withName: mouthNodeName, recursively: true)
	}
	init(biq: BiqInstance) {
		self.biqInstance = biq
		super.init()
		reload()
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init?(coder aDecoder: NSCoder) not implimented")
	}
	func reload() {
		let c = childNodes
		c.forEach { $0.removeFromParentNode() }
		if let node = biqInstance.avatarType.node {
			addChildNode(node)
			finishCreate()
		}
	}
	func finishCreate() {
		setMouth()
	}
	private func setMouth() {
		let mouthName: String
		switch biqInstance.health {
		case 75...100:
			mouthName = "mouth1-1"
		case 50..<75:
			mouthName = "mouth1-2"
		case 25..<50:
			mouthName = "mouth1-3"
		case 0..<25:
			mouthName = "mouth1-4"
		default:
			return
		}
		guard let node = standardNode(named: mouthName),
			let mouth = mouthNode else {
			return
		}
		let scale = CGFloat(1.0)
		node.scale = SCNVector3(scale, scale, scale)
		mouth.addChildNode(node)
	}
}

extension SCNNode {
	var avatarParent: AvatarNode? {
		guard let avatar = self as? AvatarNode else {
			return parent?.avatarParent
		}
		return avatar
	}
}
