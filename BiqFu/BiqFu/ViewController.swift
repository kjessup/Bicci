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

enum AvatarNode: String {
	case dog, cat, fox, bunny, elephant, frog
	static let allCases: [AvatarNode] = [.dog, .cat, .fox, .bunny, .elephant, .frog]
	func node(id: String) -> SCNNode {
		let name = self.rawValue
		let parent = SCNNode()
		if let scene = SCNScene(named: "art.scnassets/\(name).scn"),
			let node = scene.rootNode.childNode(withName: name, recursively: false) {
			let scale = Float(0.0007)
			node.scale = SCNVector3(x: scale, y: scale, z: scale)
			addName(id, to: parent, avatarDepth: boxDepth(node.boundingBox, scale: node.scale.x))
			parent.addChildNode(node)
		}
		return parent
	}
	init() {
		let rnd = Int(arc4random_uniform(UInt32(AvatarNode.allCases.count-1)))
		self = AvatarNode.allCases[rnd]
	}
	private func addName(_ name: String, to parent: SCNNode, avatarDepth: Float) {
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
		let depth = avatarDepth
		textNode.runAction(SCNAction.sequence([
			.rotateBy(x: CGFloat(.pi * -0.5), y: 0, z: 0, duration: 0.0),
			.moveBy(x: -CGFloat(width / 2), y: 0, z: CGFloat(depth), duration: 0.0)
			]))
	}
}

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
	@IBOutlet var label: UILabel!
	
	private var requests: [VNRequest] = []
	let fadeDuration: TimeInterval = 2.5
	let rotateDuration: TimeInterval = 3
	let waitDuration: TimeInterval = 0.5
	var qrDetectMode = QRDetectMode.none
	var session: ARSession { return sceneView.session }
	var processing = 0
	var foundBiqs = [String:SCNNode]()
	
	func getNode(id: String) -> SCNNode {
		let nodeType = AvatarNode()
		let node = nodeType.node(id: id)
		node.opacity = 0.0
		node.runAction(.fadeIn(duration: fadeDuration))
		return node
	}
	
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
//		let configuration = ARImageTrackingConfiguration()
//		if let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) {
//			configuration.trackingImages = referenceImages
//			configuration.maximumNumberOfTrackedImages = 2
//		}
		configuration.planeDetection = .horizontal
		let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
		sceneView.session.run(configuration, options: options)
	}

    // MARK: - ARSCNViewDelegate
	public func session(_ session: ARSession, didUpdate frame: ARFrame) {
		guard qrDetectMode != .done,
			0 == processing else {
			return
		}
		processing = 1
		
		// Create a Barcode Detection Request
		let request = VNDetectBarcodesRequest {
			request, error in
			defer {
				self.processing -= 1
			}
			// Get the first result out of the results, if there are any
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
				let topLeft = result.topLeft, bottomLeft = result.bottomLeft
				let topRight = result.topRight, bottomRight = result.bottomRight
				let biqId = url.lastPathComponent
				
				// Get the bounding box for the bar code and find the center
				var rect = result.boundingBox
				// Flip coordinates
				rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
				rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))
				
				// Get center
				let center = CGPoint(x: rect.midX, y: rect.midY)
				
				self.processing += 1
				// Go back to the main thread
				DispatchQueue.main.async {
					defer {
						self.processing -= 1
					}
					let hitTestResults = frame.hitTest(center, types: [.estimatedHorizontalPlane/*.featurePoint, .estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent*/] )
					let hitLeftBottom = frame.hitTest(bottomLeft, types: [.featurePoint])
					let hitLeftTop = frame.hitTest(topLeft, types: [.featurePoint])
					
					guard let hitTestResult = hitTestResults.first(where: { $0.type == .estimatedHorizontalPlane }) else {
						return
					}
					
					guard let bottomLeftResult = hitLeftBottom.first,
						let topLeftResult = hitLeftTop.first else {
						return
					}
					
					let bp = bottomLeftResult.worldTransform.position
					let tp = topLeftResult.worldTransform.position
					let angle = atan2(bp.z - tp.z, bp.x - tp.x)
					let transform =  hitTestResult.worldTransform
					let node: SCNNode
					if let n = self.foundBiqs[biqId] {
//						print("Updating anchor for biq \(biqId)")
						node = n
					} else {
//						print("Adding anchor for biq \(biqId)")
						node = self.getNode(id: biqId)
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
		}
		
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				request.preferBackgroundProcessing = true
				request.symbologies = [.QR]
				let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage,
																options: [:])
				try imageRequestHandler.perform([request])
			} catch {
				
			}
		}
	}
	
	// MARK: - ARSCNViewDelegate
	
	func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
		
		print("Anchor \(type(of: anchor))")
		
		// If this is our anchor, create a node
		if let name = anchor.name, anchor == foundBiqs[name] {
//			let wrapperNode = self.shipNode
//			wrapperNode.transform = SCNMatrix4(anchor.transform)
//			return wrapperNode

//			let text = SCNText(string: anchor.name, extrusionDepth: 0.0)
//			text.firstMaterial?.diffuse.contents = UIColor.orange
//			text.firstMaterial?.specular.contents = UIColor.orange
//			text.font = UIFont(name: "Optima", size: 0.04)
//			text.containerFrame = CGRect(x: 0, y: 0, width: 12, height: 44)
//			let textNode = SCNNode(geometry: text)
//			textNode.transform = SCNMatrix4(anchor.transform)
//			textNode.scale = .init(0.1, 0.1, 0.1)
//			return textNode
			
			let cube = SCNBox(width: 0.04, height: 0.04, length: 0.04, chamferRadius: 0)
			let cubeNode = SCNNode(geometry: cube)
			cubeNode.opacity = 0.5
			return cubeNode
		} else if let imageAnchor = anchor as? ARImageAnchor {
			let cube = SCNBox(width: 0.04, height: 0.04, length: 0.04, chamferRadius: 0)
			let cubeNode = SCNNode(geometry: cube)
			cubeNode.opacity = 0.5
			cubeNode.transform = .init(anchor.transform)
			return cubeNode
		}
		
		return nil
	}
	
	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		return
	}

//	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//		guard let imageAnchor = anchor as? ARImageAnchor else {
//			return
//		}
//
//		let cube = SCNBox(width: 0.04, height: 0.04, length: 0.04, chamferRadius: 0)
//		let cubeNode = SCNNode(geometry: cube)
//		cubeNode.opacity = 0.5
//		cubeNode.transform = SCNMatrix4(imageAnchor.transform)
//		sceneView.scene.rootNode.addChildNode(cubeNode)
//	}
}

