//
//  AppState.swift
//  BiqFu
//
//  Created by Kyle Jessup on 2018-07-11.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import Foundation
import SwiftCodables
import qBiqClientAPI

// don't create unless logged in
class AppState {
	private let userId: UUID
	var myBiqs: [BiqInstance] = [] {
		didSet { set(myBiqs, forKey: "myBiqs") }
	}
	var friendBiqs: [BiqInstance] = [] {
		didSet { set(friendBiqs, forKey: "friendBiqs") }
	}
	var visibleBiqs: [BiqInstance] = []
	var newBiq: AvatarNode? = nil
	init() {
		userId = Authentication.shared!.user!.id
		myBiqs = value([BiqInstance].self, forKey: "myBiqs") ?? []
		friendBiqs = value([BiqInstance].self, forKey: "friendBiqs") ?? []
	}
	func biqBy(id: DeviceURN) -> BiqInstance? {
		return myBiqs.first(where: { $0.biqDeviceItem.device.id == id }) ?? friendBiqs.first(where: { $0.biqDeviceItem.device.id == id }) ?? visibleBiqs.first(where: { $0.biqDeviceItem.device.id == id })
	}
	func flush() {
		set(myBiqs, forKey: "\(userId).myBiqs")
		set(friendBiqs, forKey: "\(userId).friendBiqs")
	}
	
	func set<E: Encodable>(_ value: E, forKey key: String) {
		if let enc = try? JSONEncoder().encode(value) {
			UserDefaults.standard.setValue(enc as Any?, forKey: "\(userId).\(key)")
		}
	}
	func value<D: Decodable>(_ type: D.Type, forKey key: String) -> D? {
		guard let v = UserDefaults.standard.value(forKey: "\(userId).\(key)"),
			let d = v as? Data else {
				return nil
		}
		return (try? JSONDecoder().decode(type, from: d)) ?? nil
	}
}
