import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let shareInboxChannelName = "com.example.app/share_inbox"
  private let pendingUrlsKey = "pendingInstagramShares"
  private var shareInboxChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ThetaShareInbox") else {
      return
    }
    shareInboxChannel = FlutterMethodChannel(
      name: shareInboxChannelName,
      binaryMessenger: registrar.messenger()
    )
    shareInboxChannel?.setMethodCallHandler { [weak self] call, result in
      guard call.method == "consume" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self?.consumePendingShares() ?? [])
    }
  }

  private func consumePendingShares() -> [String] {
    guard let appGroupId = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String else {
      return []
    }
    guard let defaults = UserDefaults(suiteName: appGroupId) else { return [] }
    let pending = defaults.stringArray(forKey: pendingUrlsKey) ?? []
    defaults.removeObject(forKey: pendingUrlsKey)
    return pending
  }
}
