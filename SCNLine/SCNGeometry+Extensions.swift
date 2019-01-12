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

	private static func getCylinderParts(
		radius: Float, height: Float, edges: Int
	) -> ([SCNVector3], [SCNVector3], [CGPoint], [UInt32]) {
		let halfHeight = height / 2
		let uStep: Float = .pi * 2 / Float(edges)
		var angle: Float = 0.0
		var nextAngle = Float.pi * 2 / Float(edges)
		var sidePositions = [SCNVector3]()
		var myVertices = [SCNVector3]()
		var myUVs = [CGPoint]()
		var myNormals = [SCNVector3]()
		var triangleIndices = [UInt32]()
		for i in 0..<edges {
			sidePositions = [
				SCNVector3(radius * cos(angle), -halfHeight, radius * sin(angle)),
				SCNVector3(radius * cos(nextAngle), -halfHeight, radius * sin(nextAngle)),
			]
			for (j, pos) in sidePositions.enumerated() {
				myVertices.append(pos)
				myNormals.append(SCNVector3(pos.x, 0, pos.z).normalized())
				myUVs.append(CGPoint(x: j % 2 == 0 ? CGFloat(uStep) * CGFloat(i) : CGFloat(uStep) * CGFloat(i + 1), y: 0))
			}
			angle += uStep
			nextAngle += uStep
		}
		myVertices.append(contentsOf: myVertices.map { $0 + SCNVector3(0, height, 0)})
		myUVs.append(contentsOf: myUVs.map { $0 + CGPoint(x: 0, y: 1)})
		for i in 0..<edges {
			let fourI = 2 * i
			let rv = Int(edges * 2)
			triangleIndices.append(UInt32(rv + 1 + fourI))
			triangleIndices.append(UInt32(1 + fourI))
			triangleIndices.append(UInt32(0 + fourI))
			triangleIndices.append(UInt32(0 + fourI))
			triangleIndices.append(UInt32(rv + 0 + fourI))
			triangleIndices.append(UInt32(rv + 1 + fourI))
		}
		return (myVertices, myNormals, myUVs, triangleIndices)
	}

	public static func line(
		points: [SCNVector3], radius: Float, edges: Int = 12,
		maxTurning: Int = 4
	) -> SCNGeometry {
		// keep this commented
		//		var (_, _, myUVs, _) = SCNGeometry.getCylinderParts(radius: 0.3, height: 1)
		var trueNormals = [SCNVector3]()
		var trueVs = [SCNVector3]()
		var trueInds = [UInt32]()
		var lastforward = SCNVector3(0, 1, 0)
		var cPoints = SCNGeometry.getCircularPoints(radius: radius, edges: edges)
		for (index, point) in points.enumerated() {
			let newRotation: simd_quatf!
			if index == 0 {
				let startDirection = (points[index + 1] - point).normalized()
				cPoints = SCNGeometry.getCircularPoints(radius: radius, edges: edges, orientation: rotationBetween2Vectors(start: lastforward, end: startDirection))
				lastforward = startDirection.normalized()
				newRotation = simd_quatf.zero()
			} else if index < points.count - 1 {
				trueVs.append(contentsOf: Array(trueVs[(trueVs.count - edges * 2)...]))
				trueNormals.append(contentsOf: cPoints.map { $0.normalized() })

				newRotation = rotationBetween2Vectors(start: lastforward, end: (points[index + 1] - points[index]).normalized())
			} else {
				newRotation = simd_quatf(angle: 0, axis: float3([1,0,0]))
			}

			if index > 0 {
				let halfRotation = newRotation.split(by: 2)
				if point.distance(vector: points[index - 1]) > radius * 2 {
					let mTurn = max(1, min(newRotation.angle / .pi, 1) * Float(maxTurning))

					if mTurn > 1 {
						let partRotation = newRotation.split(by: Float(mTurn - 1))
						let halfForward = newRotation.split(by: 2).act(lastforward)

						for i in 0..<Int(mTurn) {
							if i > 0 {
								cPoints = cPoints.map { partRotation.normalized.act($0) }
							}
							lastforward = partRotation.normalized.act(lastforward)
							trueNormals.append(contentsOf: cPoints.map { $0.normalized() })
							let angleProgress = Float(i) / Float(mTurn - 1) - 0.5
							let tangle = radius * angleProgress

							trueVs.append(contentsOf: cPoints.map { $0 + point + (halfForward.normalized() * tangle) })
							SCNGeometry.addCylinderVerts(to: &trueInds, startingAt: trueVs.count - edges * 4, edges: edges)
							lastforward = partRotation.normalized.act(lastforward)
						}
						continue
					}
				}
				// fallback and just apply the half rotation for the turn
				cPoints = cPoints.map { halfRotation.normalized.act($0) }
				lastforward = halfRotation.normalized.act(lastforward)

				trueNormals.append(contentsOf: cPoints.map { $0.normalized() })
				trueVs.append(contentsOf: cPoints.map { $0 + point })
				SCNGeometry.addCylinderVerts(to: &trueInds, startingAt: trueVs.count - edges * 4, edges: edges)
				cPoints = cPoints.map { halfRotation.normalized.act($0) }
				lastforward = halfRotation.normalized.act(lastforward)

			} else {
				cPoints = cPoints.map { newRotation.act($0) }
				lastforward = newRotation.act(lastforward)

				trueNormals.append(contentsOf: cPoints.map { $0.normalized() })
				trueVs.append(contentsOf: cPoints.map { $0 + point })

			}
		}

		let src = SCNGeometrySource(vertices: trueVs)
		let normals = SCNGeometrySource(normals: trueNormals)
		// keep this for now
		//		let textureMap = SCNGeometrySource(textureCoordinates: myUVs)
		let inds = SCNGeometryElement(indices: trueInds, primitiveType: .triangles)
		//		return (trueVs, trueInds, SCNGeometry(sources: [src, normals], elements: [inds]))
		return SCNGeometry(sources: [src, normals], elements: [inds])
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
