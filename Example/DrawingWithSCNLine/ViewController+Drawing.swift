//
//  ViewController+Drawing.swift
//  DrawingWithSCNLine
//
//  Created by Max Cobb on 12/15/18.
//  Copyright © 2018 Max Cobb. All rights reserved.
//

import ARKit
import SCNLine

var lastPoint = SCNVector3Zero
var minimumMovement: Float = 0.005

private extension SCNVector3 {
	func distance(to vector: SCNVector3) -> Float {
		let diff = SCNVector3(x - vector.x, y - vector.y, z - vector.z)
		return sqrt(diff.x * diff.x + diff.y * diff.y + diff.z * diff.z)
	}
}

extension ViewController {
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let location = touches.first?.location(in: nil) else {
			return
		}
		pointTouching = location

		begin()
		isDrawing = true
	}
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let location = touches.first?.location(in: nil) else {
			return
		}
		pointTouching = location
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		isDrawing = false
		reset()
	}

	private func begin(){
		drawingNode = SCNNode()
		sceneView.scene.rootNode.addChildNode(drawingNode!)
	}

	private func addPointAndCreateVertices() {
		guard let lastHit = self.sceneView.hitTest(self.pointTouching, options: [
			SCNHitTestOption.rootNode: cameraFrameNode, SCNHitTestOption.ignoreHiddenNodes: false]).first else {
				return
		}
		if lastHit.worldCoordinates.distance(to: lastPoint) > minimumMovement {
			hitVertices.append(lastHit.worldCoordinates)
			lastPoint = lastHit.worldCoordinates
			updateGeometry()
		}
	}

	private func updateGeometry(){
		guard hitVertices.count > 1, let drawNode = drawingNode else {
			return
		}
		let matDiffuse = drawNode.geometry?.materials.first?.diffuse.contents
		// Super inefficient for lines with many points, Want to replace with a
		// SCNLineNode class later with an addPoint() function or similar
		drawNode.geometry = SCNGeometry.line(
			points: hitVertices, radius: 0.01, edges: 12
		).0
		drawNode.geometry?.firstMaterial?.diffuse.contents = matDiffuse ?? UIColor(
			displayP3Red: CGFloat.random(in: 0...1),
			green: CGFloat.random(in: 0...1),
			blue: CGFloat.random(in: 0...1),
			alpha: 1
		)
		drawNode.geometry?.firstMaterial?.isDoubleSided = true
	}

	private func reset() {
		hitVertices.removeAll()
		drawingNode = nil
	}


	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		if isDrawing {
			addPointAndCreateVertices()
		}
	}

}
