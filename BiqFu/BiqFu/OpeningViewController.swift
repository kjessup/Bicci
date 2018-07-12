//
//  OpeningViewController.swift
//  Bicci
//
//  Created by Kyle Jessup on 2018-07-10.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import UIKit
import qBiqClientAPI
import SwiftCodables

class OpeningViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		Authentication.shared?.checkLoggedIn {
			response in
			guard let r = try? response.get(), r, let user = Authentication.shared?.user else {
				return self.main { self.performSegue(withIdentifier: "login", sender: self) }
			}
			DeviceAPI.listDevices(user: user) {
				response in
				do {
					let devices: [DeviceItem] = try response.get()
					let device: BiqDevice
					let lastObservation: ObsDatabase.BiqObservation?
					let shareCount: Int?
					let limits: [DeviceLimit]?
					
					
					
					
				} catch {
					self.alert(error)
				}
			}
			self.main { self.performSegue(withIdentifier: "biqs", sender: self) }
		}
	}

	@IBAction func unwindToOpening(segue: UIStoryboardSegue) {
		
	}
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
