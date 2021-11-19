import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SceneKit_SCNLineTests.allTests)
    ]
}
#endif
