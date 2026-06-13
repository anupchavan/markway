import MarkwayCore
import XCTest

final class MarkwayVaultPathTests: XCTestCase {
    func testURLFromPathTrimsAndExpandsTilde() {
        let url = MarkwayVaultPath.url(from: " ~/Documents ")
        XCTAssertEqual(url?.path, FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents").path)
    }

    func testURLFromPathRejectsEmptyText() {
        XCTAssertNil(MarkwayVaultPath.url(from: " \n\t "))
    }

    func testObsidianVaultDetectionRequiresObsidianFolder() throws {
        let vault = try temporaryDirectory()
        XCTAssertFalse(MarkwayVaultPath.isObsidianVault(vault))

        try FileManager.default.createDirectory(
            at: vault.appendingPathComponent(".obsidian", isDirectory: true),
            withIntermediateDirectories: true
        )
        XCTAssertTrue(MarkwayVaultPath.isObsidianVault(vault))
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("markway-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
