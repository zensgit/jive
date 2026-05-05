import Foundation

enum JiveExternalEntryLinkBuilder {
  static func transactionURL(
    entrySource: String = "deepLink",
    type: String = "expense",
    amount: Double? = nil,
    note: String? = nil,
    rawText: String? = nil,
    sourceLabel: String? = nil
  ) -> URL {
    var components = URLComponents()
    components.scheme = "jive"
    components.host = "transaction"
    components.path = "/new"

    var items = [
      URLQueryItem(name: "entrySource", value: normalizedEntrySource(entrySource)),
      URLQueryItem(name: "type", value: normalizedTransactionType(type)),
    ]
    if let sourceLabel = trimmed(sourceLabel) {
      items.append(URLQueryItem(name: "sourceLabel", value: sourceLabel))
    }
    if let amount, amount > 0 {
      items.append(URLQueryItem(name: "amount", value: formattedAmount(amount)))
    }
    if let note = trimmed(note) {
      items.append(URLQueryItem(name: "note", value: note))
    }
    if let rawText = trimmed(rawText) ?? trimmed(note) {
      items.append(URLQueryItem(name: "rawText", value: rawText))
    }

    components.queryItems = items
    return components.url!
  }

  static func quickActionURL(actionId: String) -> URL? {
    guard let id = trimmed(actionId) else { return nil }
    var components = URLComponents()
    components.scheme = "jive"
    components.host = "quick-action"
    components.queryItems = [URLQueryItem(name: "id", value: id)]
    return components.url
  }

  private static func normalizedEntrySource(_ raw: String) -> String {
    switch raw.trimmingCharacters(in: .whitespacesAndNewlines) {
    case "shareReceive", "share_receive":
      return "shareReceive"
    case "ocrScreenshot", "ocr_screenshot":
      return "ocrScreenshot"
    default:
      return "deepLink"
    }
  }

  private static func normalizedTransactionType(_ raw: String) -> String {
    let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    switch value {
    case "income", "transfer", "expense":
      return value
    default:
      return "expense"
    }
  }

  private static func formattedAmount(_ amount: Double) -> String {
    var value = String(
      format: "%.2f",
      locale: Locale(identifier: "en_US_POSIX"),
      amount
    )
    while value.contains(".") && value.last == "0" {
      value.removeLast()
    }
    if value.last == "." {
      value.removeLast()
    }
    return value
  }

  private static func trimmed(_ value: String?) -> String? {
    let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed?.isEmpty == false ? trimmed : nil
  }
}
