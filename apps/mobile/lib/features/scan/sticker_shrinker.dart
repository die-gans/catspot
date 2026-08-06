import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'cat_detection_models.dart';

/// Maximum long edge of a PNG sticker sent to the catch-keepsake callable.
const int kMaxStickerDimension = 1024;

/// Margin added around the detected cat bounding box when cropping.
const double kStickerCropMargin = 0.05;

/// If the detected box already covers at least this fraction of the image,
/// assume the platform already tight-cropped the subject and skip cropping.
const double _tightCropThreshold = 0.95;

/// Input bundle for running the shrinker on an isolate.
class ShrinkStickerInput {
  const ShrinkStickerInput({
    required this.png,
    required this.box,
    this.maxDimension = kMaxStickerDimension,
    this.margin = kStickerCropMargin,
  });

  final Uint8List png;
  final VisionBoundingBox box;
  final int maxDimension;
  final double margin;
}

/// Crop and/or resize a PNG cat sticker so the upload payload stays small.
///
/// - Decodes [png], preserving alpha.
/// - Crops to the detected bounding box ([box]) plus a small margin, unless the
///   box already fills the image (i.e. the platform already tight-cropped it).
/// - Downscales the longest edge to [maxDimension] while preserving aspect.
/// - Returns a re-encoded PNG, or the original bytes if decoding fails.
Uint8List shrinkStickerSync(Uint8List png, VisionBoundingBox box) {
  return _shrinkStickerSync(
    ShrinkStickerInput(png: png, box: box),
  );
}

/// Same as [shrinkStickerSync] but runs off the UI thread via [compute].
Future<Uint8List> shrinkStickerOnIsolate(Uint8List png, VisionBoundingBox box) {
  return compute(_shrinkStickerSync, ShrinkStickerInput(png: png, box: box));
}

/// Default shrinker used by [ScanController].
Future<Uint8List> defaultStickerShrinker(
  Uint8List png,
  VisionBoundingBox box,
) {
  return shrinkStickerOnIsolate(png, box);
}

Uint8List _shrinkStickerSync(ShrinkStickerInput input) {
  final src = img.decodePng(input.png);
  if (src == null) {
    return input.png;
  }

  final rect = input.box.toFlutterRect();

  final boxWidth = (rect.width * src.width).round();
  final boxHeight = (rect.height * src.height).round();
  final boxArea = boxWidth * boxHeight;
  final imageArea = src.width * src.height;
  final isTightCrop = boxArea >= imageArea * _tightCropThreshold;

  img.Image processed = src;
  if (!isTightCrop) {
    final boxLeft = (rect.left * src.width).round();
    final boxTop = (rect.top * src.height).round();

    final marginX = (boxWidth * input.margin).round();
    final marginY = (boxHeight * input.margin).round();

    final x = max(0, boxLeft - marginX);
    final y = max(0, boxTop - marginY);
    final cropWidth = min(src.width - x, boxWidth + 2 * marginX);
    final cropHeight = min(src.height - y, boxHeight + 2 * marginY);

    processed = img.copyCrop(
      src,
      x: x,
      y: y,
      width: cropWidth,
      height: cropHeight,
    );
  }

  if (processed.width > input.maxDimension ||
      processed.height > input.maxDimension) {
    late final int outWidth;
    late final int outHeight;
    if (processed.width >= processed.height) {
      outWidth = input.maxDimension;
      outHeight =
          (input.maxDimension * processed.height / processed.width).round();
    } else {
      outHeight = input.maxDimension;
      outWidth =
          (input.maxDimension * processed.width / processed.height).round();
    }

    processed = img.copyResize(
      processed,
      width: outWidth,
      height: outHeight,
    );
  }

  return img.encodePng(processed);
}
