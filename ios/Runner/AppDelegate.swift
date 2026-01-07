import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private let channelName = "com.jive.app/stream"
  private var eventSink: FlutterEventSink?
  private var pendingEvent: [String: Any]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterEventChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
      channel.setStreamHandler(self)
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if handleAutoURL(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    if let pending = pendingEvent {
      events(pending)
      pendingEvent = nil
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func handleAutoURL(_ url: URL) -> Bool {
    guard url.scheme == "jive" else { return false }
    let isAuto = url.host == "auto" || url.path == "/auto"
    if !isAuto { return false }

    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let items = components?.queryItems ?? []
    func value(_ name: String) -> String? {
      return items.first { $0.name == name }?.value
    }

    let payload: [String: Any] = [
      "source": value("source") ?? "Shortcut",
      "amount": value("amount") ?? "0",
      "raw_text": value("raw_text") ?? value("note") ?? "",
      "type": value("type") ?? "",
      "timestamp": Int(Date().timeIntervalSince1970 * 1000)
    ]
    sendEvent(payload)
    return true
  }

  private func sendEvent(_ payload: [String: Any]) {
    if let sink = eventSink {
      sink(payload)
    } else {
      pendingEvent = payload
    }
  }
}
