//
//  SCNGeometry+Extensions.swift
//  SCNLine
//
//  Created by Max Cobb on 12/14/18.
//  Copyright © 2018 Max Cobb. All rights reserved.
//

import SceneKit

private extension simd_quatf {
	func act(_ vector: SCNVector3) -> SCNVector3 {
		let vec = self.act(float3([vector.x, vector.y, vector.z]))
		return SCNVector3(vec.x, vec.y, vec.z)
	}
	func split(by factor: Float = 2) -> simd_quatf {
		if self.angle == 0 {
			return self
		} else {
			return simd_quatf(angle: self.angle / factor, axis: self.axis)
		}
	}
	static func zero() -> simd_quatf {
		return simd_quatf(angle: 0, axis: [1,0,0])
	}
}
private func rotationBetween2Vectors(start: SCNVector3, end: SCNVector3) -> simd_quatf {
	return simd_quaternion(simd_float3([start.x, start.y, start.z]), simd_float3([end.x, end.y, end.z]))
}
public extension SCNGeometry {

	private static func getCircularPoints(
		radius: Float, edges: Int,
		orientation: simd_quatf = simd_quatf(angle: 0, axis: float3([1,0,0]))
	) -> [SCNVector3] {
		var angle: Float = 0
		var verts = [SCNVector3]()
		let angleAdd = Float.pi * 2 / Float(edges)
		for index in 0..<edges {
			let vert = SCNVector3(radius * cos(angle), 0, radius * sin(angle))
			angle += angleAdd
			verts.append(orientation.act(vert))
			if index > 0 {
				verts.append(verts.last!)
			}
		}
		verts.append(verts.first!)
		return verts
	}

	/// Create a thick line following a series of points in 3D space
	///
	/// - Parameters:
	///   - points: Points that the tube will follow through
	///   - radius: Radius of the line or tube
	///   - edges: Number of edges the extended shape should have, recommend at least 3
	///   - maxTurning: Maximum number of additional points to be added on turns. Varies depending on degree change.
	/// - Returns: Returns a tuple of the geometry and a CGFloat containing the distance of the entire tube, including added turns.
	public static func line(
		points: [SCNVector3], radius: Float, edges: Int = 12,
		maxTurning: Int = 4
	) -> (SCNGeometry, CGFloat) {
		var trueNormals = [SCNVector3]()
		var trueUVMap = [CGPoint]()
		var trueVs = [SCNVector3]()
		var trueInds = [UInt32]()
		var lastforward = SCNVector3(0, 1, 0)
		var cPoints = SCNGeometry.getCircularPoints(radius: radius, edges: edges)
		let textureXs = cPoints.enumerated().map { (val) -> CGFloat in
			return CGFloat(val.offset) / CGFloat(edges - 1)
		}
		guard var lastLocation = points.first else {
			return (SCNGeometry(sources: [], elements: []), 0)
		}
		var lineLength: CGFloat = 0
		var lastPartRotation = simd_quatf.zero()
		for (index, point) in points.enumerated() {
			let newRotation: simd_quatf!
			if index == 0 {
				let startDirection = (points[index + 1] - point).normalized()
				cPoints = SCNGeometry.getCircularPoints(radius: radius, edges: edges, orientation: rotationBetween2Vectors(start: lastforward, end: startDirection))
				lastforward = startDirection.normalized()
				newRotation = simd_quatf.zero()
			} else if index < points.count - 1 {
				trueVs.append(contentsOf: Array(trueVs[(trueVs.count - edges * 2)...]))
				trueUVMap.append(contentsOf: Array(trueUVMap[(trueUVMap.count - edges * 2)...]))
				trueNormals.append(contentsOf: cPoints.map { $0.normalized() })

				newRotation = rotationBetween2Vectors(start: lastforward, end: (points[index + 1] - points[index]).normalized())
			} else {
				cPoints = cPoints.map { lastPartRotation.normalized.act($0) }
				newRotation = simd_quatf(angle: 0, axis: float3([1,0,0]))
			}

			if index > 0 {
				let halfRotation = newRotation.split(by: 2)
				if point.distance(vector: points[index - 1]) > radius * 2 {
					let mTurn = max(1, min(newRotation.angle / .pi, 1) * Float(maxTurning))

					if mTurn > 1 {
						let partRotation = newRotation.split(by: Float(mTurn))
						let halfForward = newRotation.split(by: 2).act(lastforward)

						for i in 0..<Int(mTurn) {
							trueNormals.append(contentsOf: cPoints.map { $0.normalized() })
							let angleProgress = Float(i) / Float(mTurn - 1) - 0.5
							let tangle = radius * angleProgress
							let nextLocation = point + (halfForward.normalized() * tangle)
							lineLength += CGFloat(lastLocation.distance(vector: nextLocation))
							lastLocation = nextLocation
							trueVs.append(contentsOf: cPoints.map { $0 + nextLocation })
							trueUVMap.append(contentsOf: textureXs.map { CGPoint(x: $0, y: lineLength) })
							SCNGeometry.addCylinderVerts(to: &trueInds, startingAt: trueVs.count - edges * 4, edges: edges)
							cPoints = cPoints.map { partRotation.normalized.act($0) }
							lastforward = partRotation.normalized.act(lastforward)
						}
						lastPartRotation = partRotation
						continue
					}
				}
				// fallback and just apply the half rotation for the turn
				cPoints = cPoints.map { halfRotation.normalized.act($0) }
				lastforward = halfRotation.normalized.act(lastforward)

				trueNormals.append(contentsOf: cPoints.map { $0.normalized() })
				trueVs.append(contentsOf: cPoints.map { $0 + point })
				lineLength += CGFloat(lastLocation.distance(vector: point))
				lastLocation = point
				trueUVMap.append(contentsOf: textureXs.map { CGPoint(x: $0, y: lineLength) })
				SCNGeometry.addCylinderVerts(to: &trueInds, startingAt: trueVs.count - edges * 4, edges: edges)
				cPoints = cPoints.map { halfRotation.normalized.act($0) }
				lastforward = halfRotation.normalized.act(lastforward)
				lastPartRotation = halfRotation
			} else {
				cPoints = cPoints.map { newRotation.act($0) }
				lastforward = newRotation.act(lastforward)

				trueNormals.append(contentsOf: cPoints.map { $0.normalized() })
				trueUVMap.append(contentsOf: textureXs.map { CGPoint(x: $0, y: lineLength) })
				trueVs.append(contentsOf: cPoints.map { $0 + point })

			}
		}

		let src = SCNGeometrySource(vertices: trueVs)
		let normals = SCNGeometrySource(normals: trueNormals)
		// keep this for now
		let textureMap = SCNGeometrySource(textureCoordinates: trueUVMap)
		let inds = SCNGeometryElement(indices: trueInds, primitiveType: .triangles)

		return (SCNGeometry(sources: [src, normals, textureMap], elements: [inds]), lineLength)
	}

	static private func addCylinderVerts(
		to array: inout [UInt32], startingAt: Int, edges: Int
	) {
		for i in 0..<edges {
			let fourI = 2 * i + startingAt
			let rv = Int(edges * 2)
			array.append(UInt32(1 + fourI + rv))
			array.append(UInt32(1 + fourI))
			array.append(UInt32(0 + fourI))
			array.append(UInt32(0 + fourI))
			array.append(UInt32(0 + fourI + rv))
			array.append(UInt32(1 + fourI + rv))
		}

	}
}
