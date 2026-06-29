import hovr_app_update
import XCTest

final class VersionCompareTests: XCTestCase {
  func testEmptyServerVersionDoesNotRequireUpdate() {
    XCTAssertFalse(
      VersionCompare.isUpdateRequired(serverVersion: "", installedVersion: "1.0.0")
    )
  }

  func testMatchingVersionsAfterTrimDoNotRequireUpdate() {
    XCTAssertFalse(
      VersionCompare.isUpdateRequired(serverVersion: " 6.2.4 ", installedVersion: "6.2.4")
    )
  }

  func testDifferentVersionsRequireUpdate() {
    XCTAssertTrue(
      VersionCompare.isUpdateRequired(serverVersion: "6.3.0", installedVersion: "6.2.4")
    )
  }
}
