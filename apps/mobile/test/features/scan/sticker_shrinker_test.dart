import 'dart:typed_data';

import 'package:catspot_mobile/features/scan/cat_detection_models.dart';
import 'package:catspot_mobile/features/scan/sticker_shrinker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _encodePng(img.Image image) {
  return img.encodePng(image);
}

img.Image _makeRgbaImage({
  required int width,
  required int height,
}) {
  return img.Image(
    width: width,
    height: height,
    numChannels: 4,
  );
}

void _fillTransparent(img.Image image) {
  for (final pixel in image) {
    pixel.setRgba(0, 0, 0, 0);
  }
}

void _fillRect(
  img.Image image, {
  required int x,
  required int y,
  required int width,
  required int height,
  required int r,
  required int g,
  required int b,
  required int a,
}) {
  for (var py = y; py < y + height && py < image.height; py++) {
    for (var px = x; px < x + width && px < image.width; px++) {
      image.setPixelRgba(px, py, r, g, b, a);
    }
  }
}

void main() {
  group('shrinkStickerSync', () {
    test('crops to the detected box and keeps the longest edge at 1024', () {
      const imageWidth = 3000;
      const imageHeight = 4000;
      const boxWidth = 600;
      const boxHeight = 800;
      const boxLeft = 1200;
      const boxTop = 1600;

      final source = _makeRgbaImage(
        width: imageWidth,
        height: imageHeight,
      );
      _fillTransparent(source);
      _fillRect(
        source,
        x: boxLeft,
        y: boxTop,
        width: boxWidth,
        height: boxHeight,
        r: 255,
        g: 0,
        b: 0,
        a: 255,
      );

      final png = _encodePng(source);
      const box = VisionBoundingBox(
        x: boxLeft / imageWidth,
        y: 1 - (boxTop + boxHeight) / imageHeight, // Vision bottom-left origin.
        width: boxWidth / imageWidth,
        height: boxHeight / imageHeight,
      );

      final shrunk = shrinkStickerSync(png, box);
      final decoded = img.decodePng(Uint8List.fromList(shrunk))!;

      final maxDimension =
          decoded.width > decoded.height ? decoded.width : decoded.height;
      expect(maxDimension, lessThanOrEqualTo(kMaxStickerDimension));

      // Aspect ratio of the box should be preserved within a pixel.
      const expectedAspect = boxWidth / boxHeight;
      final actualAspect = decoded.width / decoded.height;
      expect(actualAspect, moreOrLessEquals(expectedAspect, epsilon: 0.05));

      // The cropped cat pixel should still be present (red with alpha).
      final centerPixel = decoded.getPixel(
        decoded.width ~/ 2,
        decoded.height ~/ 2,
      );
      expect(centerPixel.r, 255);
      expect(centerPixel.a, 255);

      // A corner outside the cropped box should be transparent.
      final cornerPixel = decoded.getPixel(0, 0);
      expect(cornerPixel.a, 0);
    });

    test('preserves alpha when the whole image is shrunk without cropping', () {
      final source = _makeRgbaImage(width: 2048, height: 2048);
      _fillTransparent(source);
      _fillRect(
        source,
        x: 512,
        y: 512,
        width: 1024,
        height: 1024,
        r: 0,
        g: 0,
        b: 255,
        a: 200,
      );

      final png = _encodePng(source);
      const box = VisionBoundingBox(
        x: 0,
        y: 0,
        width: 1,
        height: 1,
      );

      final shrunk = shrinkStickerSync(png, box);
      final decoded = img.decodePng(Uint8List.fromList(shrunk))!;

      expect(decoded.width, kMaxStickerDimension);
      expect(decoded.height, kMaxStickerDimension);
      expect(decoded.numChannels, 4);

      final centerPixel = decoded.getPixel(512, 512);
      expect(centerPixel.b, 255);
      expect(centerPixel.a, 200);
    });

    test('skips cropping when the box already fills the image', () {
      final source = _makeRgbaImage(width: 512, height: 512);
      _fillTransparent(source);
      _fillRect(
        source,
        x: 0,
        y: 0,
        width: 512,
        height: 512,
        r: 0,
        g: 255,
        b: 0,
        a: 255,
      );

      final png = _encodePng(source);
      const box = VisionBoundingBox(
        x: 0,
        y: 0,
        width: 1,
        height: 1,
      );

      final shrunk = shrinkStickerSync(png, box);
      final decoded = img.decodePng(Uint8List.fromList(shrunk))!;

      expect(decoded.width, 512);
      expect(decoded.height, 512);

      final pixel = decoded.getPixel(256, 256);
      expect(pixel.g, 255);
      expect(pixel.a, 255);
    });

    test('reduces a typical catch payload to well under 1 MB', () {
      // Simulate a full-resolution phone cutout: 12 MP-ish, 4:3, alpha channel.
      final source = _makeRgbaImage(width: 4032, height: 3024);
      _fillTransparent(source);
      // Fill a cat-shaped-ish region in the middle.
      _fillRect(
        source,
        x: 1512,
        y: 1008,
        width: 1008,
        height: 1008,
        r: 128,
        g: 64,
        b: 32,
        a: 255,
      );
      // Add some noise to the cat region so PNG cannot compress it to zero.
      for (var y = 1008; y < 1008 + 1008; y += 4) {
        for (var x = 1512; x < 1512 + 1008; x += 4) {
          source.setPixelRgba(x, y, (x + y) % 256, 64, 32, 255);
        }
      }

      final original = _encodePng(source);
      const box = VisionBoundingBox(
        x: 1512 / 4032,
        y: 1 - (1008 + 1008) / 3024,
        width: 1008 / 4032,
        height: 1008 / 3024,
      );

      final shrunk = shrinkStickerSync(original, box);

      expect(shrunk.length, lessThan(1024 * 1024));
      expect(shrunk.length, lessThan(original.length));
      print(
        'shrinkStickerSync: ${original.length} bytes -> ${shrunk.length} bytes '
        '(ratio ${(original.length / shrunk.length).toStringAsFixed(1)}x)',
      );
    });
  });
}
