//
//  ViewController.swift
//  Bicci
//
//  Created by Kyle Jessup on 2018-06-29.
//  Copyright © 2018 Treefrog. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision
import SwiftCodables

extension matrix_float4x4 {
	var position: SCNVector3 {
		return SCNVector3(columns.3.x, columns.3.y, columns.3.z)
	}
}

enum QRDetectMode {
	case none, one, two, done
	@discardableResult
	mutating func advance() -> QRDetectMode {
		switch self {
		case .none:
			self = .one
		case .one:
			self = .two
		case .two:
			self = .done
		case .done:
			()
		}
		return self
	}
}

typealias BoundingBox = (min: SCNVector3, max: SCNVector3)

func boxDepth(_ box: BoundingBox, scale: Float) -> Float {
	return (box.max.z - box.min.z) * scale
}
func boxWidth(_ box: BoundingBox, scale: Float) -> Float {
	return (box.max.x - box.min.x) * scale
}

let fadeDuration: TimeInterval = 2.5

class TableViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
	@IBOutlet var label: UILabel!
	
	private var requests: [VNRequest] = []
	let rotateDuration: TimeInterval = 3
	let waitDuration: TimeInterval = 0.5
	var qrDetectMode = QRDetectMode.none
	var session: ARSession { return sceneView.session }
	var processing = 0
	var foundBiqs = [String:AvatarNode]()
	var ignoreBiqs = Set<String>()
	
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
		session.delegate = self
        sceneView.showsStatistics = true
		configureLighting()
//		sceneView.debugOptions = [.showBoundingBoxes]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
		resetTrackingConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
	
	func configureLighting() {
		sceneView.autoenablesDefaultLighting = true
		sceneView.automaticallyUpdatesLighting = true
	}
	
	func resetTrackingConfiguration() {
		qrDetectMode = .none
		let configuration = ARWorldTrackingConfiguration()
		configuration.planeDetection = .horizontal
		configuration.isLightEstimationEnabled = true
		let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
		sceneView.session.run(configuration, options: options)
	}
	
	func avatarTapped(_ avatar: AvatarNode) {
		if avatar.biqInstance.tamed {
			tamedAvatarTapped(avatar)
		} else if let owner = avatar.biqInstance.biqDeviceItem.device.ownerId {
			untamedAvatarTapped(avatar, ownerId: owner)
		} else {
			unownedUntamedAvatarTapped(avatar)
		}
	}
	
	func tamedAvatarTapped(_ avatar: AvatarNode) {
		print("tamedAvatarTapped")
	}
	
	func untamedAvatarTapped(_ avatar: AvatarNode, ownerId: UserId) {
		print("untamedAvatarTapped")
		guard let user = AppDelegate.authentication.user else {
			return
		}
		if ownerId == user.id {
			AppDelegate.state.newBiq = avatar
			performSegue(withIdentifier: "NewBiq", sender: nil)
		} else {
			// !FIX! share
		}
	}
	
	func unownedUntamedAvatarTapped(_ avatar: AvatarNode) {
		print("unownedUntamedAvatarTapped")
		AppDelegate.state.newBiq = avatar
		performSegue(withIdentifier: "NewBiq", sender: nil)
	}
	
	func pushBusyBiq(id: DeviceURN) {
		ignoreBiqs.insert(id)
	}
	
	func popBusyBiq(id: DeviceURN) {
		ignoreBiqs.remove(id)
	}
	
	// scanned a biq that is not ours and not shared to us
	func scannedUnknown(code: VNBarcodeObservation, frame: ARFrame, biqId: DeviceURN) {
		guard let user = AppDelegate.authentication.user else {
			return
		}
		// don't do anything with this biq until the situation is resolved
		pushBusyBiq(id: biqId)
		DeviceAPI.deviceInfo(user: user, deviceId: biqId) {
			response in
			do {
				let device = APIDevice(device: try response.get(),
										  shareCount: 0,
										  lastObservation: nil,
										  limits: [])
				let instance = BiqInstance(biq: device)
				DispatchQueue.main.async {
					if let owner = device.device.ownerId {
						self.scannedUnknownOwnedBiq(instance, code: code, frame: frame, biqId: biqId, owner: owner)
					} else {
						self.scannedUnknownUnownedBiq(instance, code: code, frame: frame, biqId: biqId)
					}
				}
			} catch {
				error.displayForUser()
			}
		}
	}
	
	// scanned a biq that is either owned by us or shared with us
	// it still may have not been tamed
	func scannedKnown(code result: VNBarcodeObservation, frame: ARFrame, instance: BiqInstance) {
		let topLeft = result.topLeft, bottomLeft = result.bottomLeft
		let topRight = result.topRight, bottomRight = result.bottomRight
		var rect = result.boundingBox
		// Flip coordinates
		rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
		rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))
		let center = CGPoint(x: rect.midX, y: rect.midY)
		processing += 1
		DispatchQueue.main.async {
			defer {
				self.processing -= 1
			}
			let hitTestResults = frame.hitTest(center, types: [.estimatedHorizontalPlane/*.featurePoint, .estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent*/] )
			let hitLeftBottom = frame.hitTest(bottomLeft, types: [.featurePoint])
			let hitLeftTop = frame.hitTest(topLeft, types: [.featurePoint])
			guard let hitTestResult = hitTestResults.first(where: { $0.type == .estimatedHorizontalPlane }),
				let bottomLeftResult = hitLeftBottom.first,
				let topLeftResult = hitLeftTop.first else {
					return
			}
			let bp = bottomLeftResult.worldTransform.position
			let tp = topLeftResult.worldTransform.position
			let angle = atan2(bp.z - tp.z, bp.x - tp.x)
			let transform =  hitTestResult.worldTransform
			let biqId = instance.biqDeviceItem.device.id
			let node: AvatarNode
			if let n = self.foundBiqs[biqId] {
//				print("Updating anchor for biq \(biqId)")
				node = n
			} else {
//				print("Adding anchor for biq \(biqId)")
				node = instance.node
				node.addName(biqId, to: node, avatarDepth: boxDepth(node.boundingBox, scale: node.scale.x))
				node.opacity = 0.0
				node.runAction(.fadeIn(duration: fadeDuration))
				node.transform = .init(transform)
				let c = SCNBillboardConstraint()
				c.freeAxes = SCNBillboardAxis.Y
				node.constraints = [c]
				self.foundBiqs[biqId] = node
				self.qrDetectMode.advance()
				self.sceneView.scene.rootNode.addChildNode(node)
			}
			node.runAction(SCNAction.group([
				.move(to: transform.position, duration: 0.5),
				.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 1.0)])) {
			}
		}
	}
	
	func scannedUnknownUnownedBiq(_ instance: BiqInstance, code: VNBarcodeObservation, frame: ARFrame, biqId: DeviceURN) {
		print("scannedUnknownUnownedBiq")
		AppDelegate.state.visibleBiqs.append(instance)
		popBusyBiq(id: biqId)
	}
	
	func scannedUnknownOwnedBiq(_ instance: BiqInstance, code: VNBarcodeObservation, frame: ARFrame, biqId: DeviceURN, owner: UserId) {
		print("scannedUnknownOwnedBiq")
		AppDelegate.state.visibleBiqs.append(instance)
		popBusyBiq(id: biqId)
	}
	
	@IBAction func unwindToTableView(segue: UIStoryboardSegue) {
		AppDelegate.state.newBiq = nil
	}
	
	// MARK: - ARSessionDelegate
	public func session(_ session: ARSession, didUpdate frame: ARFrame) {
		guard qrDetectMode != .done,
			0 == processing else {
				return
		}
		processing = 1
		let request = VNDetectBarcodesRequest {
			request, error in
			defer {
				self.processing -= 1
			}
			if let e = error {
				return e.displayForUser()
			}
			guard let results = request.results else {
				return
			}
			for result1 in results {
				guard let result = result1 as? VNBarcodeObservation else {
					continue
				}
				guard let value = result.payloadStringValue,
					let url = URL(string: value),
					url.host == "ubiqwe.us" else {
						continue// not a valid qBiq™ QR code
				}
				let biqId = url.lastPathComponent
				guard !self.ignoreBiqs.contains(biqId) else {
					continue
				}
				guard let instance = AppDelegate.state.biqBy(id: biqId) else {
					self.scannedUnknown(code: result, frame: frame, biqId: biqId)
					return // bail on unknown biq
				}
				self.scannedKnown(code: result, frame: frame, instance: instance)
			}
		}
		
		DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
			do {
				request.preferBackgroundProcessing = true
				request.symbologies = [.QR]
				let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, options: [:])
				try imageRequestHandler.perform([request])
			} catch {
				error.displayForUser()
			}
		}
	}
	
	// MARK: - ARSCNViewDelegate
	
	func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
		print("Anchor \(type(of: anchor))")
		return nil
	}
	
	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		return
	}
}

extension TableViewController: UIGestureRecognizerDelegate {
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		let location = gestureRecognizer.location(in: sceneView)
		let hits = sceneView.hitTest(location, options: nil)
		if let tappedNode = hits.first?.node,
			let _ = tappedNode.avatarParent {
			return true
		}
		return false
	}
	@IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
		let location = sender.location(in: sceneView)
		let hits = sceneView.hitTest(location, options: nil)
		if let tappedNode = hits.first?.node, let avatar = tappedNode.avatarParent {
			avatarTapped(avatar)
		}
	}
}

extension AvatarNode {
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
