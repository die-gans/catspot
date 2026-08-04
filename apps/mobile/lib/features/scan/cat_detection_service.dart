import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cat_detection_models.dart';

/// Dart interface for the `catspot/vision` MethodChannel.
///
/// The implementation is guarded so the app still runs on platforms where the
/// channel is unavailable (Android, tests). When unavailable, [detect] returns
/// an empty list and [isAvailable] is `false`.
abstract interface class CatDetectionService {
  /// Whether the platform channel is available on this device.
  bool get isAvailable;

  /// Run animal detection on [imageBytes].
  ///
  /// Returns a list of detections, filtered to the top label for each
  /// observation. On unsupported platforms or when the channel is missing, this
  /// returns an empty list instead of throwing.
  Future<List<CatDetection>> detect(Uint8List imageBytes);
}

/// Live platform-channel implementation backed by Apple Vision on iOS.
final class MethodChannelCatDetectionService implements CatDetectionService {
  /// Create the live detection service.
  MethodChannelCatDetectionService({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('catspot/vision');

  final MethodChannel _channel;

  @override
  bool get isAvailable => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<List<CatDetection>> detect(Uint8List imageBytes) async {
    if (!isAvailable) {
      return const [];
    }

    final dynamic raw = await _channel.invokeMethod(
      'detectCats',
      imageBytes,
    );

    if (raw == null) {
      return const [];
    }

    final list = raw as List<Object?>;
    return list
        .cast<Map<dynamic, dynamic>>()
        .map(_decodeDetection)
        .toList(growable: false);
  }

  CatDetection _decodeDetection(Map<dynamic, dynamic> map) {
    final box = map['boundingBox'] as Map<dynamic, dynamic>;
    return CatDetection(
      label: (map['label'] as Object).toString(),
      confidence: (map['confidence'] as num).toDouble(),
      boundingBox: VisionBoundingBox(
        x: (box['x'] as num).toDouble(),
        y: (box['y'] as num).toDouble(),
        width: (box['width'] as num).toDouble(),
        height: (box['height'] as num).toDouble(),
      ),
    );
  }
}
