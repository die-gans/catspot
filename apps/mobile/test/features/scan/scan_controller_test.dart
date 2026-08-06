import 'dart:typed_data';

import 'package:catspot_mobile/features/scan/cat_detection_models.dart';
import 'package:catspot_mobile/features/scan/cat_detection_service.dart';
import 'package:catspot_mobile/features/scan/keepsake_model.dart';
import 'package:catspot_mobile/features/scan/keepsake_service.dart';
import 'package:catspot_mobile/features/scan/scan_controller.dart';
import 'package:catspot_mobile/features/scan/scan_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCatDetectionService extends Mock implements CatDetectionService {}

class _MockKeepsakeService extends Mock implements KeepsakeService {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  group('ScanController', () {
    late CatDetectionService detectionService;
    late KeepsakeService keepsakeService;

    setUp(() {
      detectionService = _MockCatDetectionService();
      keepsakeService = _MockKeepsakeService();
    });

    ScanController createController() => ScanController(
          detectionService: detectionService,
          keepsakeService: keepsakeService,
          stickerShrinker: (bytes, box) async => Uint8List.fromList([...bytes, 0xaa]),
          retryDelays: const [
            Duration(milliseconds: 10),
            Duration(milliseconds: 20),
          ],
        );

    test('starts with a fresh clean state', () {
      final controller = createController();
      addTearDown(controller.dispose);

      expect(controller.state.capturedBytes, isNull);
      expect(controller.state.isolatedBytes, isNull);
      expect(controller.state.keepsake, isNull);
      expect(controller.state.error, isNull);
      expect(controller.state.detections, isEmpty);
      expect(controller.state.isCapturing, isFalse);
      expect(controller.state.isIsolating, isFalse);
      expect(controller.state.isCreatingKeepsake, isFalse);
    });

    test('retake clears captured/isolated/keepsake state', () {
      final controller = createController();
      addTearDown(controller.dispose);

      final keepsake = Keepsake(
        id: 'ks-1',
        name: 'Fluffy',
        cutoutUrl: 'https://example.com/cutout.png',
        serialNumber: 'CAT-001',
        createdAt: DateTime(2026, 8, 6),
      );
      controller.state = controller.state.copyWith(
        capturedBytes: Uint8List.fromList([1, 2, 3]),
        isolatedBytes: Uint8List.fromList([4, 5, 6]),
        keepsake: keepsake,
        error: 'Something went wrong',
        detections: const [
          // ignore: avoid_redundant_argument_values
          CatDetection(
            label: 'Cat',
            confidence: 0.95,
            boundingBox: VisionBoundingBox(
              x: 0.1,
              y: 0.1,
              width: 0.5,
              height: 0.5,
            ),
          ),
        ],
        isCapturing: true,
        isIsolating: true,
        isCreatingKeepsake: true,
      );

      controller.retake();

      expect(controller.state.capturedBytes, isNull);
      expect(controller.state.isolatedBytes, isNull);
      expect(controller.state.keepsake, isNull);
      expect(controller.state.error, isNull);
      expect(controller.state.detections, isEmpty);
      expect(controller.state.isCapturing, isFalse);
      expect(controller.state.isIsolating, isFalse);
      expect(controller.state.isCreatingKeepsake, isFalse);
      expect(controller.state.isCaptureEnabled, isTrue);
    });
    test('catchIt shows an optimistic keepsake immediately and confirms it on success', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      const detection = CatDetection(
        label: 'Cat',
        confidence: 0.95,
        boundingBox: VisionBoundingBox(
          x: 0.25,
          y: 0.25,
          width: 0.5,
          height: 0.5,
        ),
      );
      final isolated = Uint8List.fromList([1, 2, 3]);
      controller.state = controller.state.copyWith(
        isolatedBytes: isolated,
        detections: [detection],
      );

      final serverKeepsake = Keepsake(
        id: 'server-id',
        name: 'Whiskers',
        cutoutUrl: 'https://example.com/whiskers.png',
        serialNumber: 'CS-1234',
        createdAt: DateTime.utc(2026, 8, 6),
      );

      when(() => keepsakeService.saveAndCreate(any())).thenAnswer(
        (_) async => serverKeepsake,
      );

      controller.catchIt();

      // Result screen should appear immediately, before the network resolves.
      expect(controller.state.keepsake, isNotNull);
      expect(controller.state.keepsake!.serialNumber, 'CS-????');
      expect(controller.state.keepsake!.name, isNull);
      expect(controller.state.isolatedBytes, same(isolated));
      expect(controller.state.isCreatingKeepsake, isTrue);
      expect(controller.state.error, isNull);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.keepsake, serverKeepsake);
      expect(controller.state.isCreatingKeepsake, isFalse);
      expect(controller.state.error, isNull);

      final captured = verify(
        () => keepsakeService.saveAndCreate(captureAny()),
      ).captured.single as Uint8List;
      expect(captured.last, 0xaa); // shrinker ran before upload
    });

    test('catchIt retries failures and succeeds', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      const detection = CatDetection(
        label: 'Cat',
        confidence: 0.95,
        boundingBox: VisionBoundingBox(
          x: 0.25,
          y: 0.25,
          width: 0.5,
          height: 0.5,
        ),
      );
      controller.state = controller.state.copyWith(
        isolatedBytes: Uint8List.fromList([1, 2, 3]),
        detections: [detection],
      );

      final serverKeepsake = Keepsake(
        id: 'server-id',
        name: 'Luna',
        cutoutUrl: 'https://example.com/luna.png',
        serialNumber: 'CS-5678',
        createdAt: DateTime.utc(2026, 8, 6),
      );

      var attempts = 0;
      when(() => keepsakeService.saveAndCreate(any())).thenAnswer((_) async {
        attempts++;
        if (attempts < 3) {
          throw Exception('network error');
        }
        return serverKeepsake;
      });

      controller.catchIt();
      expect(controller.state.isCreatingKeepsake, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(attempts, 3);
      expect(controller.state.keepsake, serverKeepsake);
      expect(controller.state.isCreatingKeepsake, isFalse);
      expect(controller.state.error, isNull);
    });

    test('catchIt keeps the sticker and shows a retry error after retries are exhausted', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      const detection = CatDetection(
        label: 'Cat',
        confidence: 0.95,
        boundingBox: VisionBoundingBox(
          x: 0.25,
          y: 0.25,
          width: 0.5,
          height: 0.5,
        ),
      );
      final isolated = Uint8List.fromList([1, 2, 3]);
      controller.state = controller.state.copyWith(
        isolatedBytes: isolated,
        detections: [detection],
      );

      when(() => keepsakeService.saveAndCreate(any()))
          .thenThrow(Exception('server down'));

      controller.catchIt();
      final optimisticId = controller.state.keepsake!.id;

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(controller.state.keepsake, isNotNull);
      expect(controller.state.keepsake!.id, optimisticId);
      expect(controller.state.isolatedBytes, same(isolated));
      expect(controller.state.isCreatingKeepsake, isFalse);
      expect(controller.state.error, contains('Could not save'));
    });

    test('retrySave recovers from an exhausted save attempt', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      const detection = CatDetection(
        label: 'Cat',
        confidence: 0.95,
        boundingBox: VisionBoundingBox(
          x: 0.25,
          y: 0.25,
          width: 0.5,
          height: 0.5,
        ),
      );
      controller.state = controller.state.copyWith(
        isolatedBytes: Uint8List.fromList([1, 2, 3]),
        detections: [detection],
      );

      final serverKeepsake = Keepsake(
        id: 'server-id',
        name: 'Milo',
        cutoutUrl: 'https://example.com/milo.png',
        serialNumber: 'CS-9012',
        createdAt: DateTime.utc(2026, 8, 6),
      );

      var attempts = 0;
      when(() => keepsakeService.saveAndCreate(any())).thenAnswer((_) async {
        attempts++;
        if (attempts < 4) {
          throw Exception('server down');
        }
        return serverKeepsake;
      });

      controller.catchIt();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(controller.state.error, isNotNull);

      controller.retrySave();
      expect(controller.state.isCreatingKeepsake, isTrue);
      expect(controller.state.error, isNull);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(controller.state.keepsake, serverKeepsake);
      expect(controller.state.isCreatingKeepsake, isFalse);
      expect(controller.state.error, isNull);
    });
  });

  group('scanControllerProvider', () {
    ProviderContainer createContainer() {
      final detectionService = _MockCatDetectionService();
      final keepsakeService = _MockKeepsakeService();
      return ProviderContainer(
        overrides: [
          catDetectionServiceProvider.overrideWithValue(detectionService),
          keepsakeServiceProvider.overrideWithValue(keepsakeService),
        ],
      );
    }

    test('is auto-dispose and returns a fresh controller after disposal', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(scanControllerProvider.notifier);
      final keepsake = Keepsake(
        id: 'ks-1',
        name: 'Fluffy',
        cutoutUrl: 'https://example.com/cutout.png',
        serialNumber: 'CAT-001',
        createdAt: DateTime(2026, 8, 6),
      );
      controller.state = controller.state.copyWith(
        capturedBytes: Uint8List.fromList([1, 2, 3]),
        isolatedBytes: Uint8List.fromList([4, 5, 6]),
        keepsake: keepsake,
      );

      expect(controller.state.capturedBytes, isNotNull);
      expect(controller.state.keepsake, isNotNull);

      // Simulate leaving the scan route: dispose the container. A new container
      // represents re-entering the route and must create a fresh controller.
      container.dispose();

      final newContainer = createContainer();
      addTearDown(newContainer.dispose);

      final newController = newContainer.read(scanControllerProvider.notifier);
      expect(newController, isNot(same(controller)));
      expect(newController.state.capturedBytes, isNull);
      expect(newController.state.isolatedBytes, isNull);
      expect(newController.state.keepsake, isNull);
      expect(newController.state.error, isNull);
    });
  });
}
