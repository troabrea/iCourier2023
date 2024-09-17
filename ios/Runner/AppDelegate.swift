import UIKit
import Flutter
import GoogleMaps
import AppIntents

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyCTBvcej7pKYNYILF__pe4qmoo_NAzTIwk")
    GeneratedPluginRegistrant.register(with: self)
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
