//
//  NewBicViewController.swift
//  BiqFu
//
//  Created by Kyle Jessup on 2018-07-24.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import UIKit
import SwiftCodables

class NewBicViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	private func registerDevice(_ done: @escaping () -> ()) {
		guard let user = AppDelegate.authentication.user else {
			return
		}
		let device = AppDelegate.state.newBiq!.biqInstance.biqDeviceItem.device
		DeviceAPI.registerDevice(user: user, deviceId: device.id) {
			response in
			do {
				let newDevice = try response.get()
				DeviceAPI.setDeviceLimits(user: user, deviceId: newDevice.id, newLimits: []) {
					response in
					do {
						let newLimits = try response.get()
						let biqAvatar = AppDelegate.state.newBiq!
						biqAvatar.biqInstance.biqDeviceItem = .init(
							device: newDevice,
							shareCount: 0,
							lastObservation: nil,
							limits: newLimits.limits)
						DispatchQueue.main.async {
							done()
						}
					} catch {
						error.displayForUser()
					}
				}
			} catch {
				error.displayForUser()
			}
		}
	}
	
	@IBAction func tameBiq(_ sender: Any?) {
		guard let user = AppDelegate.authentication.user else {
			return
		}
		let biqAvatar = AppDelegate.state.newBiq!
		let device = biqAvatar.biqInstance.biqDeviceItem.device
		if nil == device.ownerId {
			return registerDevice {
				self.tameBiq(nil)
			}
		}
		let avatar = AvatarNodeType.random
		let str = rollStat()
		let dex = rollStat()
		let int = rollStat()
		let cha = rollStat()
		let birth = Date().timeIntervalSince1970
		let limits: [DeviceAPI.DeviceLimit] = [
			.init(limitType: .str, limitValue: Float(str), limitFlag: .ownerShared),
			.init(limitType: .dex, limitValue: Float(dex), limitFlag: .ownerShared),
			.init(limitType: .int, limitValue: Float(int), limitFlag: .ownerShared),
			.init(limitType: .cha, limitValue: Float(cha), limitFlag: .ownerShared),
			.init(limitType: .health, limitValue: Float(healthMaximum), limitFlag: .ownerShared),
			.init(limitType: .birth, limitValue: Float(birth), limitFlag: .ownerShared),
			.init(limitType: .avatar, limitValue: 0, limitValueString: avatar.rawValue, limitFlag: .ownerShared),
		]
		DeviceAPI.setDeviceLimits(user: user, deviceId: biqAvatar.biqInstance.biqDeviceItem.device.id, newLimits: limits) {
			response in
			do {
				let newLimits = try response.get()
				DispatchQueue.main.async {
					let oldItem = biqAvatar.biqInstance.biqDeviceItem
					biqAvatar.biqInstance.biqDeviceItem = .init(
						device: oldItem.device,
						shareCount: 0,
						lastObservation: nil,
						limits: newLimits.limits)
					self.performSegue(withIdentifier: "TamedBiq", sender: nil)
				}
			} catch {
				error.displayForUser()
			}
		}
		
	}
	
	func rollStat() -> Int {
		let raw = (0..<4).map { _ in return Int.random(in: 1...6) }
		let sum = raw.sorted().dropFirst().reduce(0, { $0 + $1 })
		return sum
	}
}
