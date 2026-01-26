import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler, UIColorPickerViewControllerDelegate {
  private let channelName = "com.jive.app/stream"
  private let colorPickerChannelName = "com.jive.app/color_picker"
  private var eventSink: FlutterEventSink?
  private var pendingEvent: [String: Any]?
  private var colorPickerResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterEventChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
      channel.setStreamHandler(self)
      setupColorPickerChannel(controller)
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

  private func setupColorPickerChannel(_ controller: FlutterViewController) {
    let channel = FlutterMethodChannel(name: colorPickerChannelName, binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "pickColor" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.presentColorPicker(arguments: call.arguments, result: result)
    }
  }

  private func presentColorPicker(arguments: Any?, result: @escaping FlutterResult) {
    guard #available(iOS 14.0, *) else {
      result(FlutterError(code: "unavailable", message: "iOS 14+ only", details: nil))
      return
    }
    if colorPickerResult != nil {
      result(FlutterError(code: "busy", message: "Color picker already shown", details: nil))
      return
    }
    let picker = UIColorPickerViewController()
    picker.supportsAlpha = false
    if let dict = arguments as? [String: Any], let hex = dict["hex"] as? String {
      picker.selectedColor = colorFromHex(hex)
    }
    picker.delegate = self
    colorPickerResult = result
    if let controller = window?.rootViewController {
      controller.present(picker, animated: true)
    } else {
      colorPickerResult = nil
      result(FlutterError(code: "unavailable", message: "No root view controller", details: nil))
    }
  }

  @available(iOS 14.0, *)
  func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
    let hex = hexFromColor(viewController.selectedColor)
    colorPickerResult?(hex)
    colorPickerResult = nil
  }

  private func colorFromHex(_ hex: String) -> UIColor {
    let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
    if cleaned.count != 6 { return UIColor.systemBlue }
    var value: UInt64 = 0
    guard Scanner(string: cleaned).scanHexInt64(&value) else { return UIColor.systemBlue }
    let r = CGFloat((value & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((value & 0x00FF00) >> 8) / 255.0
    let b = CGFloat(value & 0x0000FF) / 255.0
    return UIColor(red: r, green: g, blue: b, alpha: 1.0)
  }

  private func hexFromColor(_ color: UIColor) -> String {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    color.getRed(&r, green: &g, blue: &b, alpha: &a)
    let ri = Int(round(r * 255))
    let gi = Int(round(g * 255))
    let bi = Int(round(b * 255))
    return String(format: "#%02x%02x%02x", ri, gi, bi)
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
