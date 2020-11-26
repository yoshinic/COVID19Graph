import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(COVID19GraphTests.allTests),
    ]
}
#endif
