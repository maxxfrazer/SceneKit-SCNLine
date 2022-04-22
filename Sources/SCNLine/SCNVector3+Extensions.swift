//
//  SCNVector3+Extensions.swift
//  SCNPath
//
//  Created by Max Cobb on 12/10/18.
//  Copyright © 2018 Max Cobb. All rights reserved.
//

import SceneKit

// macOS uses CGFloats for describing SCNvector3.
// In order to shae the same code, this typealias allows for conversion between Floats and CGFloats when needed
#if os(macOS)
typealias UFloat = CGFloat
#elseif os(iOS)
typealias UFloat = Float
#endif

internal extension SCNVector3 {

  // Universal type for macOS and iOS allowing simultaneous compatiblity when doing operations.
  // (Remember x, y and z are CGFloats on macOS)
  var fx: Float {Float(x)}
  var fy: Float {Float(y)}
  var fz: Float {Float(z)}

  /**
   * Returns the length (magnitude) of the vector described by the SCNVector3
   */
  var length: Float {
    return sqrtf(self.lenSq)
  }

  func angleChange(to: SCNVector3) -> Float {
    let dot = self.normalized().dot(vector: to.normalized())
    return acos(dot / sqrt(self.lenSq * to.lenSq))
  }

  /**
   * Returns the squared length (magnitude) of the vector described by the SCNVector3
   */
  var lenSq: Float {
    return fx*fx + fy*fy + fz*fz
  }

  /**
   * Normalizes the vector described by the SCNVector3 to length 1.0 and returns
   * the result as a new SCNVector3.
   */
  func normalized() -> SCNVector3 {
    return self / self.length
  }

  /**
   * Calculates the distance between two SCNVector3. Pythagoras!
   */
  func distance(vector: SCNVector3) -> Float {
    return (self - vector).length
  }

  /**
   * Calculates the dot product between two SCNVector3.
   */
  func dot(vector: SCNVector3) -> Float {
    return fx * vector.fx + fy * vector.fy + fz * vector.fz
  }

  /**
   * Calculates the cross product between two SCNVector3.
   */
  func cross(vector: SCNVector3) -> SCNVector3 {
    return SCNVector3(
      y * vector.z - z * vector.y,
      z * vector.x - x * vector.z,
      x * vector.y - y * vector.x
    )
  }

  func flattened() -> SCNVector3 {
    return SCNVector3(self.x, 0, self.z)
  }

  /// Given a point and origin, rotate along X/Z plane by radian amount
  ///
  /// - parameter origin: Origin for the start point to be rotated about
  /// - parameter by: Value in radians for the point to be rotated by
  ///
  /// - returns: New SCNVector3 that has the rotation applied
  func rotate(about origin: SCNVector3, by: Float) -> SCNVector3 {
    let pointRepositionedXY = [self.fx - origin.fx, self.fz - origin.fz]
    let sinAngle = sin(by)
    let cosAngle = cos(by)
    return SCNVector3(
      x: UFloat(pointRepositionedXY[0] * cosAngle - pointRepositionedXY[1] * sinAngle + origin.fx),
      y: self.y,
      z: UFloat(pointRepositionedXY[0] * sinAngle + pointRepositionedXY[1] * cosAngle + origin.fz)
    )
  }
}

/**
 * Adds two SCNVector3 vectors and returns the result as a new SCNVector3.
 */
internal func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
  return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
internal func + (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

/**
 * Subtracts two SCNVector3 vectors and returns the result as a new SCNVector3.
 */
internal func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
  return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

/**
 * Multiplies the x, y and z fields of a SCNVector3 with the same scalar value and
 * returns the result as a new SCNVector3.
 */
internal func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
  return SCNVector3Make(UFloat(vector.fx * scalar), UFloat(vector.fy * scalar), UFloat(vector.fz * scalar))
}

/**
 * Multiplies the x and y fields of a SCNVector3 with the same scalar value.
 */
internal func *= (vector: inout SCNVector3, scalar: Float) {
  vector = (vector * scalar)
}

/**
 * Divides two SCNVector3 vectors abd returns the result as a new SCNVector3
 */
internal func / (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
  return SCNVector3Make(left.x / right.x, left.y / right.y, left.z / right.z)
}

/**
 * Divides the x, y and z fields of a SCNVector3 by the same scalar value and
 * returns the result as a new SCNVector3.
 */
internal func / (vector: SCNVector3, scalar: Float) -> SCNVector3 {
  return SCNVector3Make(UFloat(vector.fx / scalar), UFloat(vector.fy / scalar), UFloat(vector.fz / scalar))
}
