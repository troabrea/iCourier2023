import UIKit
import Flutter
import GoogleMaps
import AppIntents
import Security
import WidgetKit

private enum WidgetSessionKeychain {
  private static let service = "com.barolit.icourier.widget-session"
  private static let account = "current"

  static func save(_ sessionId: String, accessGroup: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrAccessGroup as String: accessGroup,
    ]
    let deleteStatus = SecItemDelete(query as CFDictionary)
    guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
      throw keychainError(deleteStatus)
    }
    guard !sessionId.isEmpty else {
      return
    }

    var item = query
    item[kSecValueData as String] = Data(sessionId.utf8)
    item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    let addStatus = SecItemAdd(item as CFDictionary, nil)
    guard addStatus == errSecSuccess else {
      throw keychainError(addStatus)
    }
  }

  private static func keychainError(_ status: OSStatus) -> NSError {
    NSError(
      domain: NSOSStatusErrorDomain,
      code: Int(status),
      userInfo: [NSLocalizedDescriptionKey: SecCopyErrorMessageString(status, nil) ?? "Keychain error" as CFString]
    )
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyCTBvcej7pKYNYILF__pe4qmoo_NAzTIwk")
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let widgetChannel = FlutterMethodChannel(
        name: "icourier/widget_state",
        binaryMessenger: controller.binaryMessenger
      )
      widgetChannel.setMethodCallHandler { call, result in
        guard let arguments = call.arguments as? [String: Any],
              let appGroup = arguments["appGroup"] as? String,
              let key = arguments["key"] as? String,
              let defaults = UserDefaults(suiteName: appGroup) else {
          result(FlutterError(
            code: "INVALID_WIDGET_STATE",
            message: "Widget App Group arguments are invalid.",
            details: nil
          ))
          return
        }

        switch call.method {
        case "write":
          guard let payload = arguments["payload"] as? String,
                let logoFile = arguments["logoFile"] as? String,
                let logoBytes = arguments["logoBytes"] as? FlutterStandardTypedData,
                let sessionId = arguments["sessionId"] as? String,
                let companyId = arguments["companyId"] as? String,
                let endpoint = arguments["endpoint"] as? String,
                let keychainAccessGroup = Bundle.main.object(
                  forInfoDictionaryKey: "KeychainAccessGroup"
                ) as? String,
                logoFile == URL(fileURLWithPath: logoFile).lastPathComponent,
                let containerURL = FileManager.default.containerURL(
                  forSecurityApplicationGroupIdentifier: appGroup
                ) else {
            result(FlutterError(
              code: "INVALID_WIDGET_PAYLOAD",
              message: "The widget payload or brand icon is missing.",
              details: nil
            ))
            return
          }
          do {
            try WidgetSessionKeychain.save(
              sessionId,
              accessGroup: keychainAccessGroup
            )
            try logoBytes.data.write(
              to: containerURL.appendingPathComponent(logoFile),
              options: .atomic
            )
          } catch {
            result(FlutterError(
              code: "WIDGET_SHARED_STATE_WRITE_FAILED",
              message: "The widget session or brand icon could not be stored.",
              details: error.localizedDescription
            ))
            return
          }
          defaults.set(companyId, forKey: "widget_company_id")
          defaults.set(endpoint, forKey: "widget_endpoint")
          defaults.set(payload, forKey: key)
          defaults.synchronize()
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          result(nil)
        case "clear":
          if let keychainAccessGroup = Bundle.main.object(
            forInfoDictionaryKey: "KeychainAccessGroup"
          ) as? String {
            try? WidgetSessionKeychain.save("", accessGroup: keychainAccessGroup)
          }
          defaults.removeObject(forKey: "widget_company_id")
          defaults.removeObject(forKey: "widget_endpoint")
          defaults.removeObject(forKey: key)
          defaults.synchronize()
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
}

@available(iOS 16.0, *)
struct NotificarRetiroIntent : AppIntent {
    static var title: LocalizedStringResource = "Notificar Retiro"
    func perform()  throws -> some IntentResult  {
        let controller = UIApplication.shared.delegate?.window??.rootViewController as! FlutterViewController
          
                  
      let channel = FlutterMethodChannel(name: "icourier_app_intent_channel", binaryMessenger: controller.binaryMessenger)
      
        channel.invokeMethod("notificar_retiro", arguments: [])
        
        return .result()
    }
    static let openAppWhenRun: Bool = true;
}

@available(iOS 16.0, *)
struct NotificarRetiroSiriShortCut : AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: NotificarRetiroIntent(),
                    phrases: ["Notificar Retiro en \(.applicationName)",
                              "Retirar mis paqeuetes de \(.applicationName)",
                             ],
            shortTitle:  "Notificar Retiro",
            systemImageName: "arrow.up.circle.fill")
    }
    
}
