import Flutter
import UIKit

public class ThreeDMapPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "three_d_map", binaryMessenger: registrar.messenger())
    let instance = ThreeDMapPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let factory = ThreeDMapViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "com.app.three_d_map/view")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
