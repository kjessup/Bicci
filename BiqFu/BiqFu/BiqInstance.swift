//
//  BiqInstance.swift
//  BiqFu
//
//  Created by Kyle Jessup on 2018-07-23.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import Foundation
import SwiftCodables

extension BiqDeviceLimitType {
	static let health = BiqDeviceLimitType(rawValue: 255)
	static let happiness = BiqDeviceLimitType(rawValue: 254)
	static let avatar = BiqDeviceLimitType(rawValue: 253)
}

struct BiqInstance: Codable {
	let biq: DeviceAPI.ListDevicesResponseItem
	var avatarType: AvatarNodeType {
		guard let name = biq.limits?.first(where: { $0.limitType == .avatar })?.limitValueString,
			let avatar = AvatarNodeType(rawValue: name) else {
			return AvatarNodeType()
		}
		return avatar
	}
	var health: Float {
		guard let h = biq.limits?.first(where: { $0.limitType == .health })?.limitValue else {
			return Float(Int.random(in: 0...100))
		}
		return h
	}
	var node: AvatarNode {
		return AvatarNode(biq: self)
	}
}
