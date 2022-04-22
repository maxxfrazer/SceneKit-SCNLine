//
//  SCNGeometry+Extensions.swift
//  SCNLine
//
//  Created by Max Cobb on 12/14/18.
//  Copyright © 2018 Max Cobb. All rights reserved.
//

import SceneKit

public struct GeometryParts {
  public var vertices: [SCNVector3]
  public var normals: [SCNVector3]
  public var uvs: [CGPoint]
  public var indices: [UInt32]
  func buildGeometry() -> SCNGeometry {
    let src = SCNGeometrySource(vertices: self.vertices)
    let normals = SCNGeometrySource(normals: self.normals)
    let textureMap = SCNGeometrySource(textureCoordinates: self.uvs)
    let inds = SCNGeometryElement(indices: self.indices, primitiveType: .triangles)
    return SCNGeometry(sources: [src, normals, textureMap], elements: [inds])
  }
}

private extension simd_quatf {
  func act(_ vector: SCNVector3) -> SCNVector3 {
    let vec = self.act(SIMD3<Float>([vector.fx, vector.fy, vector.fz]))
    return SCNVector3(UFloat(vec.x), UFloat(vec.y), UFloat(vec.z)) // Use UFloats
  }
  func split(by factor: Float = 2) -> simd_quatf {
    if self.angle == 0 {
      return self
    } else {
      return simd_quatf(angle: self.angle / factor, axis: self.axis)
    }
  }
  static func zero() -> simd_quatf {
    return simd_quatf(angle: 0, axis: [1, 0, 0])
  }
}
private func rotationBetween2Vectors(start: SCNVector3, end: SCNVector3) -> simd_quatf {
  return simd_quaternion(
    simd_float3([start.fx, start.fy, start.fz]),
    simd_float3([end.fx, end.fy, end.fz])
  ) // Uses Float variables instead of the CGFloats on macOS.
}
public extension SCNGeometry {

  private static func getCircularPoints(
    radius: Float, edges: Int,
    orientation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>([1, 0, 0]))
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
  /// - Returns: Returns a tuple of the geometry and a CGFloat containing the
  ///						 distance of the entire tube, including added turns.
  static func line(
    points: [SCNVector3], radius: Float, edges: Int = 12,
    maxTurning: Int = 4
    ) -> (SCNGeometry, CGFloat) {

    let (geomParts, lineLength) = SCNGeometry.getAllLineParts(
      points: points, radius: radius,
      edges: edges, maxTurning: maxTurning
    )
    if geomParts.vertices.isEmpty {
      return (SCNGeometry(sources: [], elements: []), lineLength)
    }
    return (geomParts.buildGeometry(), lineLength)
  }

  static func buildGeometry(
    vertices: [SCNVector3], normals: [SCNVector3],
    uv: [CGPoint], indices: [UInt32]
    ) -> SCNGeometry {
    let src = SCNGeometrySource(vertices: vertices)
    let normals = SCNGeometrySource(normals: normals)
    let textureMap = SCNGeometrySource(textureCoordinates: uv)
    let inds = SCNGeometryElement(indices: indices, primitiveType: .triangles)

    return SCNGeometry(sources: [src, normals, textureMap], elements: [inds])
  }

  /// This function takes in all the geometry parameters to get the vertices, normals etc
  /// It's currently grossly long, needs cleaning up as a priority.
  ///
  /// - Parameters:
  ///   - points: points for the line to be created
  ///   - radius: radius of the line
  ///   - edges: edges around each point
  ///   - maxTurning: the maximum number of points to build up a turn
  /// - Returns: All the bits to create the geometry from and the length of the result
  static func getAllLineParts(
    points: [SCNVector3], radius: Float, edges: Int = 12,
    maxTurning: Int = 4
    ) -> (GeometryParts, CGFloat) {
    if points.count < 2 {
      return (GeometryParts(vertices: [], normals: [], uvs: [], indices: []), 0)
    }
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
      return (GeometryParts(vertices: [], normals: [], uvs: [], indices: []), 0)
    }
    var lineLength: CGFloat = 0
    for (index, point) in points.enumerated() {
      let newRotation: simd_quatf!
      if index == 0 {
        let startDirection = (points[index + 1] - point).normalized()
        cPoints = SCNGeometry.getCircularPoints(
          radius: radius, edges: edges, orientation:
          rotationBetween2Vectors(start: lastforward, end: startDirection)
        )
        lastforward = startDirection.normalized()
        newRotation = simd_quatf.zero()
      } else if index < points.count - 1 {
        trueVs.append(contentsOf: Array(trueVs[(trueVs.count - edges * 2)...]))
        trueUVMap.append(contentsOf: Array(trueUVMap[(trueUVMap.count - edges * 2)...]))
        trueNormals.append(contentsOf: cPoints.map { $0.normalized() })

        newRotation = rotationBetween2Vectors(start: lastforward, end: (points[index + 1] - points[index]).normalized())
      } else {
        //				cPoints = cPoints.map { lastPartRotation.normalized.act($0) }
        newRotation = simd_quatf(angle: 0, axis: SIMD3<Float>([1, 0, 0]))
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
        //				lastPartRotation = halfRotation
      } else {
        cPoints = cPoints.map { newRotation.act($0) }
        lastforward = newRotation.act(lastforward)

        trueNormals.append(contentsOf: cPoints.map { $0.normalized() })
        trueUVMap.append(contentsOf: textureXs.map { CGPoint(x: $0, y: lineLength) })
        trueVs.append(contentsOf: cPoints.map { $0 + point })

      }
    }
    return (GeometryParts(vertices: trueVs, normals: trueNormals, uvs: trueUVMap, indices: trueInds), lineLength)
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
