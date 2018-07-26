//
//  BiqInstance.swift
//  BiqFu
//
//  Created by Kyle Jessup on 2018-07-23.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import Foundation
import SwiftCodables

typealias APIDevice = DeviceAPI.ListDevicesResponseItem

extension BiqDeviceLimitType {
	static let health = BiqDeviceLimitType(rawValue: 255)
	static let happiness = BiqDeviceLimitType(rawValue: 254)
	static let avatar = BiqDeviceLimitType(rawValue: 253)
	static let str = BiqDeviceLimitType(rawValue: 252)
	static let dex = BiqDeviceLimitType(rawValue: 251)
	static let int = BiqDeviceLimitType(rawValue: 250)
	static let cha = BiqDeviceLimitType(rawValue: 249)
	static let birth = BiqDeviceLimitType(rawValue: 248)
}

class BiqInstance: Codable {
	var biqDeviceItem: APIDevice
	var id: DeviceURN { return biqDeviceItem.device.id }
	var node: AvatarNode {
		return AvatarNode(biq: self)
	}
	var avatarType: AvatarNodeType {
		return AvatarNodeType(rawValue: limitString(ofType: .avatar, default: "")) ?? AvatarNodeType()
	}
	var health: Float {
		get {
			return limitFloat(ofType: .health, default: -1)//Float(Int.random(in: 0...100)))
		}
		set {
			guard let user = AppDelegate.authentication.user else {
				return
			}
			DeviceAPI.setDeviceLimits(user: user,
									  deviceId: biqDeviceItem.device.id,
									  newLimits: [DeviceAPI.DeviceLimit(limitType: .health, limitValue: newValue, limitFlag: .ownerShared)]) {
										response in
										_ = try? response.get()
			}
		}
	}
	var str: Int { return limitInt(ofType: .str, default: -1) }
	var dex: Int { return limitInt(ofType: .dex, default: -1) }
	var int: Int { return limitInt(ofType: .int, default: -1) }
	var cha: Int { return limitInt(ofType: .cha, default: -1) }
	var birthDate: Int { return limitInt(ofType: .birth, default: -1) }
	
	var tamed: Bool { return avatarType != .unknown }
	
	init(biq: APIDevice) {
		self.biqDeviceItem = biq
	}
	
	private func limitInt(ofType: BiqDeviceLimitType, default def: Int) -> Int {
		return Int(limitFloat(ofType: ofType, default: Float(def)))
	}
	private func limitFloat(ofType: BiqDeviceLimitType, default def: Float) -> Float {
		guard let h = biqDeviceItem.limits?.first(where: { $0.limitType == ofType })?.limitValue else {
			return def
		}
		return h
	}
	private func limitString(ofType: BiqDeviceLimitType, default def: String) -> String {
		guard let h = biqDeviceItem.limits?.first(where: { $0.limitType == ofType })?.limitValueString else {
			return def
		}
		return h
	}
}
