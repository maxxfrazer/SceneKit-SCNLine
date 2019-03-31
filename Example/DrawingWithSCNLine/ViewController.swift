//
//  ViewController.swift
//  DrawingWithSCNLine
//
//  Created by Max Cobb on 12/15/18.
//  Copyright © 2018 Max Cobb. All rights reserved.
//

import ARKit

class ViewController: UIViewController {

	var sceneView = ARSCNView(frame: .zero)

	var drawingNode: SCNNode?

	var centerVerticesCount: Int32 = 0
	var hitVertices: [SCNVector3] = []

	var pointTouching: CGPoint = .zero
	var isDrawing: Bool = false

	/// Used for calculating where to draw using hitTesting
	var cameraFrameNode = SCNNode(geometry: SCNFloor())

	override func viewDidLoad() {
		super.viewDidLoad()

		self.sceneView.frame = self.view.bounds
		self.sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.view.addSubview(sceneView)

		// Set the view's delegate
		sceneView.delegate = self

		// Show statistics such as fps and timing information
		sceneView.showsStatistics = true

		sceneView.autoenablesDefaultLighting = true

		self.cameraFrameNode.isHidden = true
		self.sceneView.pointOfView?.addChildNode(self.cameraFrameNode)
		cameraFrameNode.position.z = -0.5
		cameraFrameNode.eulerAngles.x = -.pi / 2
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Create a session configuration
		let configuration = ARWorldTrackingConfiguration()

		// Run the view's session
		sceneView.session.run(configuration)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		// Pause the view's session
		sceneView.session.pause()
	}
}
