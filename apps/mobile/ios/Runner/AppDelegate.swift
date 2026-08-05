import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Register all pub plugins first. This call is a simple registration entry
    // point and does not throw in Swift; we log success/failure explicitly so
    // release crashes in this delegate are easier to diagnose.
    NSLog("Catspot AppDelegate: registering pub plugins via GeneratedPluginRegistrant")
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    NSLog("Catspot AppDelegate: pub plugins registered")

    // Register custom MethodChannel plugins defensively. Missing registrars are
    // logged but never propagated as thrown exceptions back to the engine delegate.
    registerCustomPlugin(named: "CatDetectionPlugin", registry: engineBridge.pluginRegistry) { registrar in
      CatDetectionPlugin.register(with: registrar)
    }
    registerCustomPlugin(named: "GalleryPlugin", registry: engineBridge.pluginRegistry) { registrar in
      GalleryPlugin.register(with: registrar)
    }
  }

  private func registerCustomPlugin(
    named pluginName: String,
    registry: FlutterPluginRegistry,
    register: (FlutterPluginRegistrar) -> Void
  ) {
    guard let registrar = registry.registrar(forPlugin: pluginName) else {
      NSLog("Catspot AppDelegate: no registrar for \(pluginName)")
      return
    }
    register(registrar)
    NSLog("Catspot AppDelegate: \(pluginName) registered")
  }
}
