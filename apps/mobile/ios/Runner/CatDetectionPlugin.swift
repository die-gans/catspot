import Flutter
import UIKit
import Vision

/// Minimal MethodChannel shim exposing Apple Vision `VNRecognizeAnimalsRequest`.
///
/// Channel: `catspot/vision`
/// Method: `detectCats`
/// Argument: `Uint8List` JPEG/PNG bytes.
/// Returns: list of `{label, confidence, boundingBox: {x, y, width, height}}`
///          where coordinates are normalized in Vision's bottom-left-origin space.
final class CatDetectionPlugin: NSObject {
  private static let channelName = "catspot/vision"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = CatDetectionPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private func handleDetectCats(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let bytes = call.arguments as? FlutterStandardTypedData else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected Uint8List image bytes", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let imageData = bytes.data
      guard let uiImage = UIImage(data: imageData) else {
        DispatchQueue.main.async {
          result(FlutterError(code: "DECODE_ERROR", message: "Could not decode image bytes", details: nil))
        }
        return
      }

      let request = VNRecognizeAnimalsRequest { request, error in
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(code: "VISION_ERROR", message: error.localizedDescription, details: nil))
          }
          return
        }

        guard let observations = request.results as? [VNRecognizedObjectObservation] else {
          DispatchQueue.main.async {
            result([])
          }
          return
        }

        let detections: [[String: Any]] = observations.compactMap { observation in
          guard let topLabel = observation.labels.first else { return nil }
          let box = observation.boundingBox
          return [
            "label": topLabel.identifier,
            "confidence": topLabel.confidence,
            "boundingBox": [
              "x": box.origin.x,
              "y": box.origin.y,
              "width": box.size.width,
              "height": box.size.height,
            ],
          ]
        }

        DispatchQueue.main.async {
          result(detections)
        }
      }

      guard let cgImage = uiImage.cgImage else {
        DispatchQueue.main.async {
          result(FlutterError(code: "DECODE_ERROR", message: "UIImage has no CGImage backing", details: nil))
        }
        return
      }

      // Prefer 1:1 input orientation handling; Vision will use image orientation
      // metadata when present. For JPEGs from the camera plugin this is usually
      // sufficient for the spike; production should pass explicit orientation.
      let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
      do {
        try handler.perform([request])
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "VISION_ERROR", message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}

extension CatDetectionPlugin: FlutterPlugin {
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "detectCats":
      handleDetectCats(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
