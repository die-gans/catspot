import 'package:catspot_mobile/features/collection/collection_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KeepsakeStreamMapper.fromDocs', () {
    test('maps fake Firestore document data into keepsakes preserving order', () {
      final now = DateTime.utc(2026, 8, 5, 12, 0);
      final earlier = now.subtract(const Duration(hours: 2));

      final docs = <({String id, Map<String, dynamic> data})>[
        (
          id: 'doc-1',
          data: {
            'name': 'Newest Catch',
            'cutoutUrl': 'https://example.com/new.png',
            'serialNumber': 'CS-1001',
            'createdAt': Timestamp.fromDate(now),
            'uid': 'user-123',
          },
        ),
        (
          id: 'doc-2',
          data: {
            'name': 'Older Catch',
            'imageUrl': 'https://example.com/old.png',
            'serialNumber': 'CS-1000',
            'createdAt': Timestamp.fromDate(earlier),
            'uid': 'user-123',
          },
        ),
      ];

      final keepsakes = KeepsakeStreamMapper.fromDocs(docs);

      expect(keepsakes.length, 2);
      expect(keepsakes[0].id, 'doc-1');
      expect(keepsakes[0].name, 'Newest Catch');
      expect(keepsakes[0].cutoutUrl, 'https://example.com/new.png');
      expect(keepsakes[0].createdAt.millisecondsSinceEpoch,
          now.millisecondsSinceEpoch);

      expect(keepsakes[1].id, 'doc-2');
      expect(keepsakes[1].cutoutUrl, 'https://example.com/old.png');
      expect(keepsakes[1].createdAt.millisecondsSinceEpoch,
          earlier.millisecondsSinceEpoch);
    });

    test('returns an empty list for no documents', () {
      final keepsakes = KeepsakeStreamMapper.fromDocs([]);
      expect(keepsakes, isEmpty);
    });

    test('tolerates missing imageUrl/cutoutUrl fallback in stream data', () {
      final keepsakes = KeepsakeStreamMapper.fromDocs([
        (
          id: 'doc-3',
          data: {
            'name': 'Fallback Catch',
            'imageUrl': 'https://example.com/fallback.png',
            'serialNumber': 'CS-1002',
            'createdAt': 1754404800000,
            'uid': 'user-123',
          },
        ),
      ]);

      expect(keepsakes.single.cutoutUrl, 'https://example.com/fallback.png');
    });

    test('maps a null name while waiting for server backfill', () {
      final keepsakes = KeepsakeStreamMapper.fromDocs([
        (
          id: 'doc-4',
          data: {
            'name': null,
            'cutoutUrl': 'https://example.com/unnamed.png',
            'serialNumber': 'CS-1003',
            'createdAt': 1754404800000,
            'uid': 'user-123',
          },
        ),
      ]);

      expect(keepsakes.single.name, isNull);
      expect(keepsakes.single.cutoutUrl, 'https://example.com/unnamed.png');
    });
  });
}
