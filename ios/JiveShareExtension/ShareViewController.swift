import UIKit

final class ShareViewController: UIViewController {
  private static let plainTextType = "public.plain-text"
  private static let utf8PlainTextType = "public.utf8-plain-text"
  private static let textType = "public.text"
  private static let urlType = "public.url"

  private var didStart = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !didStart else { return }
    didStart = true

    loadSharedPayload { [weak self] payload in
      DispatchQueue.main.async {
        self?.openJive(with: payload)
      }
    }
  }

  private func loadSharedPayload(completion: @escaping (JiveSharePayload) -> Void) {
    let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
    let subject = firstSubject(in: items)
    let providers = items.flatMap { $0.attachments ?? [] }
    loadFirstString(from: providers) { text in
      completion(JiveSharePayload(rawText: text, subject: subject))
    }
  }

  private func firstSubject(in items: [NSExtensionItem]) -> String? {
    for item in items {
      if let title = item.attributedTitle?.string.trimmingCharacters(in: .whitespacesAndNewlines),
         !title.isEmpty {
        return title
      }
      if let text = item.attributedContentText?.string.trimmingCharacters(in: .whitespacesAndNewlines),
         !text.isEmpty {
        return text
      }
    }
    return nil
  }

  private func loadFirstString(
    from providers: [NSItemProvider],
    completion: @escaping (String?) -> Void
  ) {
    let typeIdentifiers = [
      Self.plainTextType,
      Self.utf8PlainTextType,
      Self.textType,
      Self.urlType,
    ]
    for provider in providers {
      for typeIdentifier in typeIdentifiers where provider.hasItemConformingToTypeIdentifier(typeIdentifier) {
        provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
          completion(Self.stringValue(from: item))
        }
        return
      }
    }
    completion(nil)
  }

  private static func stringValue(from item: NSSecureCoding?) -> String? {
    if let value = item as? String {
      return trimmed(value)
    }
    if let value = item as? URL {
      return trimmed(value.absoluteString)
    }
    if let value = item as? NSAttributedString {
      return trimmed(value.string)
    }
    return nil
  }

  private func openJive(with payload: JiveSharePayload) {
    let url = JiveExternalEntryLinkBuilder.transactionURL(
      entrySource: "shareReceive",
      rawText: payload.rawText,
      sourceLabel: payload.sourceLabel
    )

    extensionContext?.open(url) { [weak self] _ in
      self?.extensionContext?.completeRequest(returningItems: nil)
    }
  }

  private static func trimmed(_ value: String?) -> String? {
    let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed?.isEmpty == false ? trimmed : nil
  }
}

private struct JiveSharePayload {
  let rawText: String?
  let subject: String?

  var sourceLabel: String {
    guard let subject = subject?.trimmingCharacters(in: .whitespacesAndNewlines),
          !subject.isEmpty else {
      return "来自 iOS 系统分享"
    }
    return "来自 iOS 系统分享：\(subject)"
  }
}
