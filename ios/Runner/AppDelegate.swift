import UIKit
import Flutter
import GoogleMaps
import AppIntents
import WidgetKit

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
          guard let payload = arguments["payload"] as? String else {
            result(FlutterError(
              code: "INVALID_WIDGET_PAYLOAD",
              message: "The widget payload is missing.",
              details: nil
            ))
            return
          }
          defaults.set(payload, forKey: key)
          defaults.synchronize()
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          result(nil)
        case "clear":
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
