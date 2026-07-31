import Flutter
import UIKit

enum AppUpdateChannelConstants {
  static let channelName = "hovr_app_update"
  static let methodConfigure = "configure"
  static let methodPrompt = "promptIfUpdateRequired"
  static let methodPromptRestart = "promptRestartToApplyUpdate"
  static let methodGetInstalledVersion = "getInstalledVersion"
  static let methodGetAppInfo = "getAppInfo"
}

enum UpdateDialogMode {
  case store
  case restart
}

public class HovrAppUpdatePlugin: NSObject, FlutterPlugin {
  private static var updateDialogShownThisSession = false
  private static var iosAppStoreId: String?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: AppUpdateChannelConstants.channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = HovrAppUpdatePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case AppUpdateChannelConstants.methodConfigure:
      handleConfigure(call: call, result: result)
    case AppUpdateChannelConstants.methodPrompt:
      handlePrompt(call: call, result: result)
    case AppUpdateChannelConstants.methodPromptRestart:
      handlePromptRestart(result: result)
    case AppUpdateChannelConstants.methodGetInstalledVersion:
      handleGetInstalledVersion(result: result)
    case AppUpdateChannelConstants.methodGetAppInfo:
      handleGetAppInfo(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleGetInstalledVersion(result: @escaping FlutterResult) {
    guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Installed version missing", details: nil))
      return
    }
    result(currentVersion)
  }

  private func handleGetAppInfo(result: @escaping FlutterResult) {
    let info = Bundle.main.infoDictionary ?? [:]
    let appName = (info["CFBundleDisplayName"] as? String)
        ?? (info["CFBundleName"] as? String)
        ?? ""
    let packageName = Bundle.main.bundleIdentifier ?? ""
    let version = (info["CFBundleShortVersionString"] as? String) ?? ""
    let buildNumber = (info["CFBundleVersion"] as? String) ?? ""
    result([
      "appName": appName,
      "packageName": packageName,
      "version": version,
      "buildNumber": buildNumber,
    ])
  }

  private func handleConfigure(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let storeId = args["iosAppStoreId"] as? String,
          !storeId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      result(FlutterError(code: "CONFIGURE_REQUIRED", message: "iosAppStoreId is required", details: nil))
      return
    }
    Self.iosAppStoreId = storeId.trimmingCharacters(in: .whitespacesAndNewlines)
    result(nil)
  }

  private func handlePrompt(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let storeId = Self.iosAppStoreId, !storeId.isEmpty else {
      result(FlutterError(code: "CONFIGURE_REQUIRED", message: "Call configure before promptIfUpdateRequired", details: nil))
      return
    }

    guard let args = call.arguments as? [String: Any],
          let serverVersion = args["serverVersion"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "serverVersion is required", details: nil))
      return
    }

    guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Installed version missing", details: nil))
      return
    }

    let updateRequired = VersionCompare.isUpdateRequired(
      serverVersion: serverVersion,
      installedVersion: currentVersion
    )
    if !updateRequired {
      result(promptResult(updateRequired: false, dialogShown: false))
      return
    }

    DispatchQueue.main.async {
      guard Self.topViewController() != nil else {
        result(FlutterError(code: "NO_ACTIVITY", message: "No view controller available", details: nil))
        return
      }
      let dialogShown = self.presentUpdateDialogIfNeeded(mode: .store, appStoreId: storeId)
      result(self.promptResult(updateRequired: true, dialogShown: dialogShown))
    }
  }

  private func handlePromptRestart(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      guard Self.topViewController() != nil else {
        result(FlutterError(code: "NO_ACTIVITY", message: "No view controller available", details: nil))
        return
      }
      let dialogShown = self.presentUpdateDialogIfNeeded(mode: .restart, appStoreId: nil)
      result(self.promptResult(updateRequired: true, dialogShown: dialogShown))
    }
  }

  private func presentUpdateDialogIfNeeded(mode: UpdateDialogMode, appStoreId: String?) -> Bool {
    if Self.updateDialogShownThisSession {
      return false
    }

    guard let topVC = Self.topViewController() else {
      return false
    }

    Self.updateDialogShownThisSession = true

    let alert = UIAlertController(
      title: "Update Required",
      message: "A new version of the app is available. Please update to continue.",
      preferredStyle: .alert
    )

    alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { _ in
      switch mode {
      case .store:
        if let appStoreId,
           let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appStoreId)") {
          UIApplication.shared.open(url)
        }
      case .restart:
        exit(0)
      }
    }))

    alert.addAction(UIAlertAction(title: "Skip", style: .cancel, handler: nil))
    topVC.present(alert, animated: true, completion: nil)
    return true
  }

  private func promptResult(updateRequired: Bool, dialogShown: Bool) -> [String: Bool] {
    [
      "updateRequired": updateRequired,
      "dialogShown": dialogShown,
    ]
  }

  private static func topViewController() -> UIViewController? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: { $0.isKeyWindow })?
      .rootViewController
  }
}
