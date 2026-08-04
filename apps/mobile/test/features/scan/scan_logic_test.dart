import 'package:catspot_mobile/features/scan/cat_detection_gate.dart';
import 'package:catspot_mobile/features/scan/cat_detection_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VisionBoundingBox.toFlutterRect', () {
    test('flips bottom-left origin to top-left origin', () {
      // Vision box anchored at bottom-left: x=0.25, y=0.2, w=0.5, h=0.6.
      // In Flutter top-left coordinates:
      // top = 1 - y - height = 1 - 0.2 - 0.6 = 0.2
      // left = x = 0.25
      const box = VisionBoundingBox(
        x: 0.25,
        y: 0.2,
        width: 0.5,
        height: 0.6,
      );
      final rect = box.toFlutterRect();

      expect(rect.left, moreOrLessEquals(0.25));
      expect(rect.top, moreOrLessEquals(0.2));
      expect(rect.width, moreOrLessEquals(0.5));
      expect(rect.height, moreOrLessEquals(0.6));
    });

    test('handles a box that fills the whole image', () {
      const box = VisionBoundingBox(x: 0, y: 0, width: 1, height: 1);
      final rect = box.toFlutterRect();

      expect(rect.left, moreOrLessEquals(0));
      expect(rect.top, moreOrLessEquals(0));
      expect(rect.width, moreOrLessEquals(1));
      expect(rect.height, moreOrLessEquals(1));
    });

    test('handles a box touching the top edge in Flutter space', () {
      // Vision: y=0.9, height=0.1 => top in Flutter = 1 - 0.9 - 0.1 = 0.
      const box = VisionBoundingBox(x: 0.1, y: 0.9, width: 0.8, height: 0.1);
      final rect = box.toFlutterRect();

      expect(rect.top, moreOrLessEquals(0));
      expect(rect.bottom, moreOrLessEquals(0.1));
    });
  });

  group('CatDetectionGate', () {
    CatDetection cat({double confidence = 0.9}) => CatDetection(
          label: 'Cat',
          confidence: confidence,
          boundingBox: const VisionBoundingBox(
            x: 0.1,
            y: 0.1,
            width: 0.5,
            height: 0.5,
          ),
        );

    CatDetection dog() => const CatDetection(
          label: 'Dog',
          confidence: 0.9,
          boundingBox: VisionBoundingBox(
            x: 0.1,
            y: 0.1,
            width: 0.5,
            height: 0.5,
          ),
        );

    test('starts disabled', () {
      final gate = CatDetectionGate();
      expect(gate.isCaptureEnabled, isFalse);
      expect(gate.streak, 0);
    });

    test('enables capture after two consecutive cat frames', () {
      final gate = CatDetectionGate();
      gate.onFrame([cat()]);
      expect(gate.isCaptureEnabled, isFalse);
      gate.onFrame([cat()]);
      expect(gate.isCaptureEnabled, isTrue);
    });

    test('resets streak on a frame without a cat', () {
      final gate = CatDetectionGate();
      gate.onFrame([cat()]);
      gate.onFrame([cat()]);
      expect(gate.isCaptureEnabled, isTrue);

      gate.onFrame([dog()]);
      expect(gate.isCaptureEnabled, isFalse);
      expect(gate.streak, 0);
    });

    test('ignores low-confidence cat detections', () {
      final gate = CatDetectionGate();
      gate.onFrame([cat(confidence: 0.49)]);
      gate.onFrame([cat(confidence: 0.49)]);
      expect(gate.isCaptureEnabled, isFalse);
    });

    test('reset clears the streak', () {
      final gate = CatDetectionGate();
      gate.onFrame([cat()]);
      gate.onFrame([cat()]);
      gate.reset();
      expect(gate.isCaptureEnabled, isFalse);
      expect(gate.streak, 0);
    });
  });
}
