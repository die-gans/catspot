import 'package:catspot_mobile/features/scan/keepsake_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Keepsake.fromJson', () {
    test('parses a Cloud Functions response with _id and epoch millis', () {
      final createdAt = DateTime.utc(2026, 8, 5, 12, 0);
      final keepsake = Keepsake.fromJson({
        '_id': 'callable-id',
        'name': 'Whiskers',
        'cutoutUrl': 'https://example.com/cutout.png',
        'serialNumber': 'CS-0001',
        'createdAt': createdAt.millisecondsSinceEpoch,
      });

      expect(keepsake.id, 'callable-id');
      expect(keepsake.name, 'Whiskers');
      expect(keepsake.cutoutUrl, 'https://example.com/cutout.png');
      expect(keepsake.serialNumber, 'CS-0001');
      expect(keepsake.createdAt.millisecondsSinceEpoch,
          createdAt.millisecondsSinceEpoch);
    });

    test('prefers id over _id and imageUrl fallback when cutoutUrl missing', () {
      final keepsake = Keepsake.fromJson(const {
        'id': 'doc-id',
        '_id': 'ignored',
        'name': 'Mittens',
        'imageUrl': 'https://example.com/image.png',
        'serialNumber': 'CS-0002',
        'createdAt': 0,
      });

      expect(keepsake.id, 'doc-id');
      expect(keepsake.cutoutUrl, 'https://example.com/image.png');
    });

    test('parses createdAt as a Firestore Timestamp', () {
      final createdAt = DateTime.utc(2026, 8, 5, 12, 0);
      final keepsake = Keepsake.fromJson({
        'id': 'ts-id',
        'name': 'Shadow',
        'cutoutUrl': 'https://example.com/shadow.png',
        'serialNumber': 'CS-0003',
        'createdAt': Timestamp.fromDate(createdAt),
      });

      expect(keepsake.createdAt.millisecondsSinceEpoch,
          createdAt.millisecondsSinceEpoch);
    });

    test('parses createdAt as an ISO-8601 string', () {
      final createdAt = DateTime.utc(2026, 8, 5, 12, 0);
      final keepsake = Keepsake.fromJson({
        'id': 'str-id',
        'name': 'Luna',
        'cutoutUrl': 'https://example.com/luna.png',
        'serialNumber': 'CS-0004',
        'createdAt': createdAt.toIso8601String(),
      });

      expect(keepsake.createdAt.millisecondsSinceEpoch,
          createdAt.millisecondsSinceEpoch);
    });

    test('uses a current timestamp when createdAt is null', () {
      final before = DateTime.now();
      final keepsake = Keepsake.fromJson(const {
        'id': 'null-id',
        'name': 'Pepper',
        'cutoutUrl': 'https://example.com/pepper.png',
        'serialNumber': 'CS-0005',
        'createdAt': null,
      });
      final after = DateTime.now();

      expect(keepsake.createdAt.isAfter(before) || keepsake.createdAt == before, isTrue);
      expect(keepsake.createdAt.isBefore(after) || keepsake.createdAt == after, isTrue);
    });

    test('tolerates a null name from the server placeholder', () {
      final keepsake = Keepsake.fromJson(const {
        'id': 'placeholder-id',
        'name': null,
        'cutoutUrl': 'https://example.com/placeholder.png',
        'serialNumber': 'CS-0008',
        'createdAt': 0,
      });

      expect(keepsake.name, isNull);
    });
  });

  group('Keepsake.fromFirestore', () {
    test('uses the document id and maps document data', () {
      final createdAt = DateTime.utc(2026, 8, 5, 12, 0);
      final keepsake = Keepsake.fromFirestore(
        'firestore-doc-id',
        {
          'name': 'Ginger',
          'imageUrl': 'https://example.com/ginger.png',
          'serialNumber': 'CS-0006',
          'createdAt': Timestamp.fromDate(createdAt),
          'uid': 'user-123',
        },
      );

      expect(keepsake.id, 'firestore-doc-id');
      expect(keepsake.name, 'Ginger');
      expect(keepsake.cutoutUrl, 'https://example.com/ginger.png');
      expect(keepsake.serialNumber, 'CS-0006');
      expect(keepsake.createdAt.millisecondsSinceEpoch,
          createdAt.millisecondsSinceEpoch);
    });

    test('maps a null name while waiting for the backfill trigger', () {
      final createdAt = DateTime.utc(2026, 8, 5, 12, 0);
      final keepsake = Keepsake.fromFirestore(
        'firestore-doc-id',
        {
          'name': null,
          'cutoutUrl': 'https://example.com/new.png',
          'serialNumber': 'CS-0009',
          'createdAt': Timestamp.fromDate(createdAt),
          'uid': 'user-123',
        },
      );

      expect(keepsake.name, isNull);
      expect(keepsake.cutoutUrl, 'https://example.com/new.png');
    });
  });

  group('Keepsake.toJson', () {
    test('round-trips through epoch millis', () {
      final createdAt = DateTime.utc(2026, 8, 5, 12, 0);
      final keepsake = Keepsake(
        id: 'roundtrip-id',
        name: 'Simba',
        cutoutUrl: 'https://example.com/simba.png',
        serialNumber: 'CS-0007',
        createdAt: createdAt,
      );

      final json = keepsake.toJson();
      expect(json['_id'], 'roundtrip-id');
      expect(json['name'], 'Simba');
      expect(json['cutoutUrl'], 'https://example.com/simba.png');
      expect(json['serialNumber'], 'CS-0007');
      expect(json['createdAt'], createdAt.millisecondsSinceEpoch);
    });

    test('serializes a null name', () {
      final keepsake = Keepsake(
        id: 'null-name-id',
        name: null,
        cutoutUrl: 'https://example.com/noname.png',
        serialNumber: 'CS-0010',
        createdAt: DateTime.utc(2026, 8, 5, 12, 0),
      );

      final json = keepsake.toJson();
      expect(json['name'], isNull);
    });
  });
}
