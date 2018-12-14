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
}
private func rotationBetween2Vectors(start: SCNVector3, end: SCNVector3) -> simd_quatf {
	return simd_quaternion(simd_float3([start.x, start.y, start.z]), simd_float3([end.x, end.y, end.z]))
}
public extension SCNGeometry {
	//	public static func getCircularPoints(radius: Float, orientation: )
	private static func getCircularPoints(
		radius: Float,
		orientation: simd_quatf = simd_quatf(angle: 0, axis: float3([0,0,0])),
		smoothness: Int
		) -> [SCNVector3] {
		var angle: Float = 0
		var verts = [SCNVector3]()
		let angleAdd = Float.pi * 2 / Float(smoothness)
		for index in 0..<smoothness {
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

	private static func getCylinderParts(radius: Float, height: Float, smoothness: Int) -> ([SCNVector3], [SCNVector3], [CGPoint], [UInt32]) {
		let halfHeight = height / 2;
		let uStep: Float = .pi * 2 / Float(smoothness);
		var angle: Float = 0.0;
		var nextAngle = Float.pi * 2 / Float(smoothness);
		var sidePositions = [SCNVector3]()
		var myVertices = [SCNVector3]()
		var myUVs = [CGPoint]()
		var myNormals = [SCNVector3]()
		var triangleIndices = [UInt32]()
		for i in 0..<smoothness {
			//			print(angle)
			//			print(nextAngle)
			sidePositions = [
				SCNVector3(radius * cos(angle), -halfHeight, radius * sin(angle)),
				SCNVector3(radius * cos(nextAngle), -halfHeight, radius * sin(nextAngle)),
			]
			for (j, pos) in sidePositions.enumerated() {
				myVertices.append(pos)
				myNormals.append(SCNVector3(pos.x, 0, pos.z).normalized())
				myUVs.append(CGPoint(x: j % 2 == 0 ? CGFloat(uStep) * CGFloat(i) : CGFloat(uStep) * CGFloat(i + 1), y: 0))
			}
			angle += uStep;
			nextAngle += uStep;
		}
		myVertices.append(contentsOf: myVertices.map { $0 + SCNVector3(0, height, 0)})
		myUVs.append(contentsOf: myUVs.map { $0 + CGPoint(x: 0, y: 1)})
		for i in 0..<smoothness {
			let fourI = 2 * i
			let rv = Int(smoothness * 2)
			triangleIndices.append(UInt32(rv + 1 + fourI));
			triangleIndices.append(UInt32(1 + fourI));
			triangleIndices.append(UInt32(0 + fourI));
			triangleIndices.append(UInt32(0 + fourI));
			triangleIndices.append(UInt32(rv + 0 + fourI));
			triangleIndices.append(UInt32(rv + 1 + fourI));
		}
		return (myVertices, myNormals, myUVs, triangleIndices)
	}

	public static func joinTube(points: [SCNVector3], radius: Float, smoothness: Int = 12) -> ([SCNVector3], [UInt32], SCNGeometry) {
		// keep this
		//		var (_, _, myUVs, _) = SCNGeometry.getCylinderParts(radius: 0.3, height: 1)
		var trueNormals = [SCNVector3]()
		var trueVs = [SCNVector3]()
		var trueInds = [UInt32]()
		var lastforward = SCNVector3(0, 1, 0)
		var cPoints = SCNGeometry.getCircularPoints(radius: radius, smoothness: smoothness)
		for (index, point) in points.enumerated() {
			let newRotation: simd_quatf!
			if index == 0 {
				newRotation = rotationBetween2Vectors(start: lastforward, end: (points[index + 1] - point))
			} else if index < points.count - 1 {
				trueVs.append(contentsOf: Array(trueVs[(trueVs.count - smoothness * 2)...]))
				trueNormals.append(contentsOf: cPoints.map { $0.normalized() })

				newRotation = rotationBetween2Vectors(start: lastforward, end: (points[index + 1] - points[index]).normalized())
			} else {
				newRotation = simd_quatf(angle: 0, axis: float3([0,0,0]))
			}

			if index > 0 {
				let halfRotation: simd_quatf = simd_quatf(angle: newRotation.angle / 2, axis: newRotation.axis)
				if newRotation.angle > .pi / 4 && point.distance(vector: points[index - 1]) > radius * 2 {
					// messy in this if statement, fix later
					let quarterRotation: simd_quatf = simd_quatf(angle: halfRotation.angle / 2, axis: newRotation.axis)

					lastforward = quarterRotation.normalized.act(lastforward)
					trueNormals.append(contentsOf: cPoints.map { $0.normalized() })
					trueVs.append(contentsOf: cPoints.map { $0 + point - (lastforward.normalized() * radius) })
					SCNGeometry.addCylinderVerts(to: &trueInds, startingAt: trueVs.count - smoothness * 4, smoothness: smoothness)

					cPoints = cPoints.map { halfRotation.normalized.act($0) }
					lastforward = quarterRotation.normalized.act(lastforward)

					trueNormals.append(contentsOf: cPoints.map { $0.normalized() })
					trueVs.append(contentsOf: cPoints.map { $0 + point })
					SCNGeometry.addCylinderVerts(to: &trueInds, startingAt: trueVs.count - smoothness * 4, smoothness: smoothness)

					cPoints = cPoints.map { halfRotation.normalized.act($0) }
					lastforward = quarterRotation.normalized.act(lastforward)

					trueNormals.append(contentsOf: cPoints.map { $0.normalized() })
					trueVs.append(contentsOf: cPoints.map { $0 + point + lastforward.normalized() * radius})
					SCNGeometry.addCylinderVerts(to: &trueInds, startingAt: trueVs.count - smoothness * 4, smoothness: smoothness)
					lastforward = quarterRotation.normalized.act(lastforward)
				} else {
					cPoints = cPoints.map { halfRotation.normalized.act($0) }
					lastforward = halfRotation.normalized.act(lastforward)

					trueNormals.append(contentsOf: cPoints.map { $0.normalized() })
					trueVs.append(contentsOf: cPoints.map { $0 + point })
					SCNGeometry.addCylinderVerts(to: &trueInds, startingAt: trueVs.count - smoothness * 4, smoothness: smoothness)
				}
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
		return (trueVs, trueInds, SCNGeometry(sources: [src, normals], elements: [inds]))
	}

	static private func addCylinderVerts(to array: inout [UInt32], startingAt: Int, smoothness: Int) {
		for i in 0..<smoothness {
			let fourI = 2 * i + startingAt
			let rv = Int(smoothness * 2)
			array.append(UInt32(rv + 1 + fourI));
			array.append(UInt32(1 + fourI));
			array.append(UInt32(0 + fourI));
			array.append(UInt32(0 + fourI));
			array.append(UInt32(rv + 0 + fourI));
			array.append(UInt32(rv + 1 + fourI));
		}

	}
}
