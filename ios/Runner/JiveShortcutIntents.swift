import AppIntents
import Foundation
import UIKit

enum JiveShortcutLinkBuilder {
  static func transactionURL(
    type: String = "expense",
    amount: Double? = nil,
    note: String? = nil,
    sourceLabel: String = "来自 iOS 快捷指令"
  ) -> URL {
    JiveExternalEntryLinkBuilder.transactionURL(
      entrySource: "deepLink",
      type: type,
      amount: amount,
      note: note,
      rawText: note,
      sourceLabel: sourceLabel
    )
  }

  static func quickActionURL(actionId: String) -> URL? {
    JiveExternalEntryLinkBuilder.quickActionURL(actionId: actionId)
  }
}

@available(iOS 16.0, *)
enum JiveShortcutTransactionType: String, AppEnum {
  case expense
  case income
  case transfer

  static var typeDisplayRepresentation = TypeDisplayRepresentation(
    name: "交易类型"
  )

  static var caseDisplayRepresentations: [JiveShortcutTransactionType: DisplayRepresentation] = [
    .expense: DisplayRepresentation(title: "支出"),
    .income: DisplayRepresentation(title: "收入"),
    .transfer: DisplayRepresentation(title: "转账"),
  ]
}

@available(iOS 16.0, *)
struct OpenJiveTransactionIntent: AppIntent {
  static var title: LocalizedStringResource = "打开 Jive 记一笔"
  static var description = IntentDescription("打开 Jive 的结构化记账编辑器，并预填快捷指令提供的信息。")
  static var openAppWhenRun = true

  @Parameter(title: "交易类型")
  var type: JiveShortcutTransactionType

  @Parameter(title: "金额")
  var amount: Double?

  @Parameter(title: "备注")
  var note: String?

  init() {
    self.type = .expense
  }

  init(
    type: JiveShortcutTransactionType = .expense,
    amount: Double? = nil,
    note: String? = nil
  ) {
    self.type = type
    self.amount = amount
    self.note = note
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    let url = JiveShortcutLinkBuilder.transactionURL(
      type: type.rawValue,
      amount: amount,
      note: note
    )
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
    return .result()
  }
}

@available(iOS 16.0, *)
struct RunJiveQuickActionIntent: AppIntent {
  static var title: LocalizedStringResource = "运行 Jive 快速动作"
  static var description = IntentDescription("通过快速动作 ID 打开 Jive One Touch 入口，例如 template:42。")
  static var openAppWhenRun = true

  @Parameter(title: "快速动作 ID")
  var actionId: String

  init() {
    self.actionId = "template:"
  }

  init(actionId: String) {
    self.actionId = actionId
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    if let url = JiveShortcutLinkBuilder.quickActionURL(actionId: actionId) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    } else {
      UIApplication.shared.open(
        JiveShortcutLinkBuilder.transactionURL(),
        options: [:],
        completionHandler: nil
      )
    }
    return .result()
  }
}

@available(iOS 16.0, *)
struct JiveShortcutsProvider: AppShortcutsProvider {
  static var shortcutTileColor: ShortcutTileColor = .teal

  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: OpenJiveTransactionIntent(),
      phrases: [
        "用 \(.applicationName) 记一笔",
        "在 \(.applicationName) 新增账单",
      ],
      shortTitle: "记一笔",
      systemImageName: "plus.circle.fill"
    )
  }
}
