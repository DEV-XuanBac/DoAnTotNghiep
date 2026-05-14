import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 13.0, *) {
      WorkmanagerPlugin.registerPeriodicTask(
        withIdentifier: "com.example.hanziilearnapp.vocabulary.periodic",
        frequency: NSNumber(value: 3 * 60 * 60)
      )
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
