//
//  SCNLineNode.swift
//  SCNLine
//
//  Created by Max Cobb on 1/23/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

import SceneKit

public class SCNLineNode: SCNNode {
	private var vertices = [SCNVector3]()
	public private(set) var length: CGFloat = 0
	private var points: [SCNVector3]
	private var radius: Float
	private var edges: Int
	private var maxTurning: Int
	public var gParts: GeometryParts?

	public override init() {
		self.points = []
		self.radius = 0.1
		self.edges = 12
		self.maxTurning = 4
		super.init()
	}
	public init(with points: [SCNVector3] = [], radius: Float = 1, edges: Int = 12, maxTurning: Int = 4) {
		self.points = points
		self.radius = radius
		self.edges = edges
		self.maxTurning = maxTurning
		super.init()
		if !points.isEmpty {
			let (geomParts, len) = SCNGeometry.getAllLineParts(
				points: points, radius: radius,
				edges: edges, maxTurning: maxTurning
			)
			self.gParts = geomParts
			self.geometry = geomParts.buildGeometry()
			self.length = len
		}
	}

	public func update(points: [SCNVector3]) {
		self.points = points
		if !points.isEmpty {
			let (geomParts, len) = SCNGeometry.getAllLineParts(
				points: points, radius: radius,
				edges: edges, maxTurning: maxTurning
			)
			self.gParts = geomParts
			self.geometry = geomParts.buildGeometry()
			self.length = len
		} else {
			self.geometry = nil
			self.length = 0
		}
	}
	func getlastAverages() -> SCNVector3 {
		let len = self.gParts!.vertices.count - 1
		let lastPoints = self.gParts?.vertices[(len - self.edges * 4)...(len - self.edges * 2)]
		let avg = lastPoints!.reduce(SCNVector3Zero, { (total, npoint) -> SCNVector3 in
			return total + npoint
		}) / Float(self.edges * 2)
		return avg
	}
	public func add(point: SCNVector3) {
		self.points.append(point)
		self.update(points: points)

		// TODO: optimise this function to not recalculate all points
		// close attempt below, rotations mess up though
		/*
		let len = self.gParts!.vertices.count - 1
		let lastPoints = self.gParts?.vertices[(len - self.edges * 4)...(len - self.edges * 2)]
		let avg = lastPoints!.reduce(SCNVector3Zero, { (total, npoint) -> SCNVector3 in
		return total + npoint
		}) / Float(self.edges * 2)
		//		print(avg)
		var (geomParts, newGeomLen) = SCNGeometry.getAllLineParts(
			points: [avg, points.last!, point], radius: self.radius,
			edges: self.edges, maxTurning: self.maxTurning
		)
		self.gParts?.vertices.removeLast(self.edges * 2)
		geomParts.vertices.removeFirst(self.edges * 2)
		geomParts.normals.removeFirst(self.edges * 4)
		geomParts.uvs.removeFirst(self.edges * 4)
		//		geomParts.indices.removeFirst(self.edges * 3)
		geomParts.indices = geomParts.indices.map {
		return $0 + UInt32(self.gParts!.vertices.count)
		}
		self.gParts?.vertices.append(contentsOf: geomParts.vertices)
		self.gParts?.normals.append(contentsOf: geomParts.normals)
		self.gParts?.uvs.append(contentsOf: geomParts.uvs)
		self.gParts?.indices.append(contentsOf: geomParts.indices)
		self.geometry = self.gParts!.buildGeometry()*/
	}
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
