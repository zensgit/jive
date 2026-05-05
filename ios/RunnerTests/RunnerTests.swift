import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  func testShortcutTransactionURLBuildsStructuredEntryLink() {
    let url = JiveShortcutLinkBuilder.transactionURL(
      type: "income",
      amount: 12.50,
      note: "午餐退款",
      sourceLabel: "来自测试"
    )

    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let query = Dictionary(
      uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value) }
    )

    XCTAssertEqual(url.scheme, "jive")
    XCTAssertEqual(url.host, "transaction")
    XCTAssertEqual(url.path, "/new")
    XCTAssertEqual(query["entrySource"]!, "deepLink")
    XCTAssertEqual(query["sourceLabel"]!, "来自测试")
    XCTAssertEqual(query["type"]!, "income")
    XCTAssertEqual(query["amount"]!, "12.5")
    XCTAssertEqual(query["note"]!, "午餐退款")
    XCTAssertEqual(query["rawText"]!, "午餐退款")
  }

  func testShortcutTransactionURLFallsBackToExpenseForUnknownType() {
    let url = JiveShortcutLinkBuilder.transactionURL(type: "other")

    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let type = components?.queryItems?.first { $0.name == "type" }?.value

    XCTAssertEqual(type, "expense")
  }

  func testQuickActionURLRejectsBlankIds() {
    XCTAssertNil(JiveShortcutLinkBuilder.quickActionURL(actionId: "  "))
  }

  func testQuickActionURLBuildsTemplateEntryLink() {
    let url = JiveShortcutLinkBuilder.quickActionURL(actionId: "template:42")
    let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
    let id = components?.queryItems?.first { $0.name == "id" }?.value

    XCTAssertEqual(url?.scheme, "jive")
    XCTAssertEqual(url?.host, "quick-action")
    XCTAssertEqual(id, "template:42")
  }

}
