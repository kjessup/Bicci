//
//  BiqsViewController.swift
//  Bicci
//
//  Created by Kyle Jessup on 2018-07-11.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import UIKit
import SwiftCodables
import qBiqClientAPI

private let reuseIdentifier = "BiqCell"
private let headerReuseIdentifier = "BiqHeader"

enum BiqsTableSection: Int, CaseIterable {
	case myBiqs, friendBiqs, visibleBiqs
	var headerName: String {
		switch self {
		case .visibleBiqs:
			return "Visible Biqs"
		case .myBiqs:
			return "Your Biqs"
		case .friendBiqs:
			return "Friend Biqs"
		}
	}
}

extension BiqInstance {
	func limit(_ type: BiqDeviceLimitType) -> String? {
		return biqDeviceItem.limits?.filter({ $0.limitType == type }).first?.limitValueString
	}
	var color: UIColor {
		if let str = limit(.colour), let c = UIColor(hex: str) {
			return c
		}
		return UIColor.blue
	}
}

struct BiqCollectionItem: Codable {
	var index: IndexPath
	var expanded = false
	var instance: BiqInstance {
		if index.section == BiqsTableSection.myBiqs.rawValue {
			return AppDelegate.state.myBiqs[index.item]
		}
		return AppDelegate.state.friendBiqs[index.item]
	}
	init(index: IndexPath, expanded: Bool = false) {
		self.index = index
		self.expanded = expanded
	}
}

class BiqsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	@IBOutlet var collectionView: UICollectionView!
	@IBOutlet var collectionViewLayout: UICollectionViewLayout!
	var biqs: [[BiqCollectionItem]] = [[],[],[]] {
		didSet {
			AppDelegate.state.set([biqs[0], biqs[1]], forKey: "biqsTableCache")
		}
	}
    override func viewDidLoad() {
        super.viewDidLoad()
		collectionView!.register(UINib(nibName: "BiqCollectionViewCell", bundle: nil),
								 forCellWithReuseIdentifier: reuseIdentifier)
		collectionView.register(UINib(nibName: "BiqCollectionViewHeader", bundle: nil),
								forSupplementaryViewOfKind: "UICollectionElementKindSectionHeader",
								withReuseIdentifier: headerReuseIdentifier)
		let b0 = (0..<AppDelegate.state.myBiqs.count).map { BiqCollectionItem(index: IndexPath(item: $0, section: 0)) }
		let b1 = (0..<AppDelegate.state.friendBiqs.count).map { BiqCollectionItem(index: IndexPath(item: $0, section: 1)) }
		biqs = [b0, b1, []]
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		collectionView.reloadData()
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
	
	@IBAction func unwindToBiqs(segue: UIStoryboardSegue) {
		
	}

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return BiqsTableSection.allCases.count-1//?? remove visible biqs?
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return biqs[section].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BiqCollectionViewCell
		cell.set(biqs[indexPath.section][indexPath.item])
		return cell
    }
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionViewLayout.invalidateLayout()
		let cell = collectionView.cellForItem(at: indexPath) as! BiqCollectionViewCell
		collectionView.performBatchUpdates({
			biqs[indexPath.section][indexPath.item].expanded = !biqs[indexPath.section][indexPath.item].expanded
			cell.toggleExpanded()
		}, completion: nil)
	}
	
	func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		guard kind == "UICollectionElementKindSectionHeader",
			let sec = BiqsTableSection(rawValue: indexPath.section) else {
			return UICollectionReusableView()
		}
		let cell = collectionView.dequeueReusableSupplementaryView(
									ofKind: kind,
									withReuseIdentifier: headerReuseIdentifier,
									for: indexPath) as! BiqCollectionViewHeader
		cell.nameLabel.text = sec.headerName
		return cell
	}

	@IBAction func logOut(_ sender: Any) {
		AppDelegate.state.flush()
		Authentication.shared?.logout {
			response in
			self.main {
				try? response.get()
				AppDelegate.state = nil
				self.performSegue(withIdentifier: "logout", sender: self)
			}
		}
	}
	// MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */
	
	// MARK: UICollectionViewDelegateFlowLayout
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		if biqs[indexPath.section][indexPath.item].expanded {
			return expandedContentSize
		}
		return contractedContentSize
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		return CGSize(width: 360, height: 45)
	}

}
