import 'dart:convert';

import 'package:catspot_mobile/features/scan/keepsake_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult<T> extends Mock
    implements HttpsCallableResult<T> {}

class MockHttpClient extends Mock implements http.Client {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseFunctions functions;
  late MockHttpsCallable callable;
  late MockHttpClient httpClient;
  late KeepsakeService service;

  setUp(() {
    functions = MockFirebaseFunctions();
    callable = MockHttpsCallable();
    httpClient = MockHttpClient();
    service = KeepsakeService(
      firebaseFunctions: functions,
      httpClient: httpClient,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('catspot/gallery'),
      null,
    );
  });

  group('KeepsakeService.saveAndCreate', () {
    test('calls catchKeepsake with base64 PNG and returns the record', () async {
      const id = 'catch-id';
      const serialNumber = 'CS-5000';
      final createdAt = DateTime.utc(2026, 8, 5, 12, 0);
      final result = MockHttpsCallableResult<Map<Object?, Object?>>();

      when(() => functions.httpsCallable('catchKeepsake'))
          .thenReturn(callable);
      when(() => callable.call<Map<Object?, Object?>>(any()))
          .thenAnswer((_) async => result);
      when(() => result.data).thenReturn({
        'id': id,
        'name': null,
        'cutoutUrl': 'https://example.com/cutout.png',
        'serialNumber': serialNumber,
        'createdAt': createdAt.millisecondsSinceEpoch,
      });

      final png = Uint8List.fromList([0, 1, 2, 255]);
      final keepsake = await service.saveAndCreate(png);

      expect(keepsake.id, id);
      expect(keepsake.name, isNull);
      expect(keepsake.cutoutUrl, 'https://example.com/cutout.png');
      expect(keepsake.serialNumber, serialNumber);

      final captured = verify(() => callable.call<Map<Object?, Object?>>(
            captureAny(),
          )).captured.single as Map<String, dynamic>;
      expect(captured['pngBase64'], base64Encode(png));
    });

    test('keeps the Photos-library save best-effort and non-blocking', () async {
      final result = MockHttpsCallableResult<Map<Object?, Object?>>();

      when(() => functions.httpsCallable('catchKeepsake'))
          .thenReturn(callable);
      when(() => callable.call<Map<Object?, Object?>>(any()))
          .thenAnswer((_) async => result);
      when(() => result.data).thenReturn({
        'id': 'id',
        'name': 'Fluffy',
        'cutoutUrl': 'https://example.com/cutout.png',
        'serialNumber': 'CS-5001',
        'createdAt': DateTime.utc(2026, 8, 5, 12, 0).millisecondsSinceEpoch,
      });

      // Simulate a Photos denial — the save should not throw.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('catspot/gallery'),
        (call) async => throw MissingPluginException(call.method),
      );

      final png = Uint8List.fromList([255]);
      await service.saveAndCreate(png);

      // Wait a beat so the unawaited gallery call has a chance to run.
      await Future<void>.delayed(Duration.zero);

      verify(() => callable.call<Map<Object?, Object?>>(any())).called(1);
    });
  });
}
