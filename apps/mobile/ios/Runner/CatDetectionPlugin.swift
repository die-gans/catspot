import Flutter
import UIKit
import Vision

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
          DispatchQueue.main.async { result([]) }
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

        DispatchQueue.main.async { result(detections) }
      }

      guard let cgImage = uiImage.cgImage else {
        DispatchQueue.main.async {
          result(FlutterError(code: "DECODE_ERROR", message: "UIImage has no CGImage backing", details: nil))
        }
        return
      }

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

  private func handleIsolateSubject(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let bytes = call.arguments as? FlutterStandardTypedData else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected Uint8List image bytes", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let imageData = bytes.data
      guard let rawImage = UIImage(data: imageData) else {
        DispatchQueue.main.async {
          result(FlutterError(code: "DECODE_ERROR", message: "Could not decode image", details: nil))
        }
        return
      }
      // Bake in the EXIF orientation so Vision sees the image right-side-up.
      let uiImage = rawImage.withNormalizedOrientation()
      guard let cgImage = uiImage.cgImage else {
        DispatchQueue.main.async {
          result(FlutterError(code: "DECODE_ERROR", message: "Could not decode image", details: nil))
        }
        return
      }

      let request = VNGenerateForegroundInstanceMaskRequest()
      let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])

      do {
        try handler.perform([request])
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "VISION_ERROR", message: error.localizedDescription, details: nil))
        }
        return
      }

      guard let observation = request.results?.first else {
        DispatchQueue.main.async {
          result(FlutterError(code: "NO_SUBJECT", message: "No foreground subject found", details: nil))
        }
        return
      }

      do {
        let maskedBuffer = try observation.generateMaskedImage(
          ofInstances: observation.allInstances,
          from: handler,
          croppedToInstancesExtent: true
        )

        let ciImage = CIImage(cvPixelBuffer: maskedBuffer)
        let ciContext = CIContext()
        guard let cgResult = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "RENDER_ERROR", message: "Could not render isolated image", details: nil))
          }
          return
        }

        let isolated = UIImage(cgImage: cgResult)
        guard let pngData = isolated.pngData() else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ENCODE_ERROR", message: "Could not encode PNG", details: nil))
          }
          return
        }

        DispatchQueue.main.async {
          result(FlutterStandardTypedData(bytes: pngData))
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "MASK_ERROR", message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}

private extension UIImage {
  /// Returns a copy of the image with orientation baked into the pixel data.
  ///
  /// Camera JPEGs carry an EXIF orientation flag but keep pixels in sensor
  /// order. Vision's coordinate system assumes `.up`, so passing the raw
  /// cgImage produces a rotated mask. Drawing into a renderer applies the
  /// transform, yielding a `.up` image Vision handles correctly.
  func withNormalizedOrientation() -> UIImage {
    guard imageOrientation != .up else { return self }
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in
      draw(in: CGRect(origin: .zero, size: size))
    }
  }
}

extension CatDetectionPlugin: FlutterPlugin {
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "detectCats":
      handleDetectCats(call, result: result)
    case "isolateSubject":
      handleIsolateSubject(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
