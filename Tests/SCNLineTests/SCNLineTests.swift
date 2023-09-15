import XCTest
import SceneKit
@testable import SCNLine

final class SCNLineTests: XCTestCase {
    func testGetAllLineParts() {
        // Setup test inputs
        let radius: Float = 1.0
        let edges: Int = 12
        let maxTurning: Int = 4

        let points: [SCNVector3] = [
            SCNVector3(x: 0.0, y: 0.0, z: 0.0),
            SCNVector3(x: 1.0, y: 1.0, z: 1.0),
            SCNVector3(x: 2.0, y: 2.0, z: 2.0)
        ]

        let (geometryParts, length) = SCNGeometry.getAllLineParts(
            points: points, radius: radius, edges: edges, maxTurning: maxTurning
        )

        // Test the output
        XCTAssertEqual(geometryParts.vertices.count, 96)
        XCTAssertEqual(geometryParts.normals.count, geometryParts.vertices.count)
        XCTAssertEqual(geometryParts.uvs.count, geometryParts.vertices.count)
        XCTAssertGreaterThan(length, 3)
    }

}
