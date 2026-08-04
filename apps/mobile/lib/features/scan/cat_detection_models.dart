import 'dart:ui';

/// Normalized bounding box returned by Apple Vision.
///
/// Vision uses a bottom-left origin: `y` is the distance from the bottom edge.
/// Flutter's canvas uses a top-left origin, so [toFlutterRect] flips the Y axis.
class VisionBoundingBox {
  /// Create a normalized bounding box in Vision's coordinate space.
  const VisionBoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Distance from the left edge, in [0, 1].
  final double x;

  /// Distance from the bottom edge, in [0, 1].
  final double y;

  /// Box width relative to image width, in [0, 1].
  final double width;

  /// Box height relative to image height, in [0, 1].
  final double height;

  /// Convert this box to a Flutter [Rect] using a top-left origin.
  ///
  /// The result is still normalized; multiply by the display size before
  /// painting.
  Rect toFlutterRect() {
    return Rect.fromLTWH(x, 1.0 - y - height, width, height);
  }
}

/// A single animal detection result from the platform channel.
class CatDetection {
  /// Create a detection result.
  const CatDetection({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  /// Animal identifier, e.g. `Cat` or `Dog`.
  final String label;

  /// Confidence in [0, 1].
  final double confidence;

  /// Normalized bounding box in Vision's bottom-left-origin space.
  final VisionBoundingBox boundingBox;
}
