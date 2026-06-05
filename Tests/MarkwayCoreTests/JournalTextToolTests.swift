import XCTest
@testable import MarkwayCore

final class JournalTextToolTests: XCTestCase {
    func testSanitizedEnvironmentRemovesXcodeDyldVariables() {
        let environment = JournalTextTool.sanitizedSubprocessEnvironment([
            "DYLD_INSERT_LIBRARIES": "/Applications/Xcode.app/libViewDebuggerSupport.dylib",
            "DYLD_FRAMEWORK_PATH": "/Applications/Xcode.app/Frameworks",
            "__XPC_DYLD_INSERT_LIBRARIES": "/Applications/Xcode.app/libViewDebuggerSupport.dylib",
            "__XCODE_BUILT_PRODUCTS_DIR_PATHS": "/tmp/DerivedData",
            "OS_ACTIVITY_DT_MODE": "YES",
            "PATH": "/usr/bin",
            "HOME": "/Users/test"
        ])

        XCTAssertNil(environment["DYLD_INSERT_LIBRARIES"])
        XCTAssertNil(environment["DYLD_FRAMEWORK_PATH"])
        XCTAssertNil(environment["__XPC_DYLD_INSERT_LIBRARIES"])
        XCTAssertNil(environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"])
        XCTAssertNil(environment["OS_ACTIVITY_DT_MODE"])
        XCTAssertEqual(environment["PATH"], "/usr/bin")
        XCTAssertEqual(environment["HOME"], "/Users/test")
    }
}
