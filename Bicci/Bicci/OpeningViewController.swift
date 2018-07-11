//
//  OpeningViewController.swift
//  Bicci
//
//  Created by Kyle Jessup on 2018-07-10.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import UIKit

class OpeningViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		self.performSegue(withIdentifier: "biqs", sender: self)
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
