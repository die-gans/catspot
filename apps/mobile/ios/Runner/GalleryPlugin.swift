import Flutter
import Photos
import UIKit

/// MethodChannel plugin for saving images to the device photo library.
///
/// Channel: `catspot/gallery`
/// Method:  `saveImage` — argument: Uint8List PNG/JPEG bytes, returns Bool on success.
final class GalleryPlugin: NSObject {
  private static let channelName = "catspot/gallery"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = GalleryPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private func handleSaveImage(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let bytes = call.arguments as? FlutterStandardTypedData else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected Uint8List image bytes", details: nil))
      return
    }

    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
      guard status == .authorized || status == .limited else {
        DispatchQueue.main.async {
          result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library access denied", details: nil))
        }
        return
      }

      PHPhotoLibrary.shared().performChanges({
        let request = PHAssetCreationRequest.forAsset()
        request.addResource(with: .photo, data: bytes.data, options: nil)
      }) { success, error in
        DispatchQueue.main.async {
          if success {
            result(true)
          } else {
            result(FlutterError(
              code: "SAVE_ERROR",
              message: error?.localizedDescription ?? "Unknown save error",
              details: nil
            ))
          }
        }
      }
    }
  }
}

extension GalleryPlugin: FlutterPlugin {
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "saveImage":
      handleSaveImage(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
