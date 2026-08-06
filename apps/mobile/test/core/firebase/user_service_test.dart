import 'package:catspot_mobile/core/firebase/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUser extends Fake implements User {
  _FakeUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });

  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  final String? photoURL;
}

void main() {
  group('UserDocumentData', () {
    test('builds a complete user document from a Firebase user', () {
      final now = DateTime.utc(2026, 8, 5, 12, 0);
      final user = _FakeUser(
        uid: 'user-123',
        email: 'test@example.com',
        displayName: 'Test User',
        photoURL: 'https://example.com/photo.png',
      );

      final data = UserDocumentData.fromFirebaseUser(user);

      final after = DateTime.now().toUtc().add(const Duration(seconds: 1));

      expect(data.uid, 'user-123');
      expect(data.email, 'test@example.com');
      expect(data.displayName, 'Test User');
      expect(data.photoURL, 'https://example.com/photo.png');
      expect(data.xp, 0);
      expect(data.coins, 0);
      expect(data.createdAt.isAfter(now.subtract(const Duration(seconds: 1))), isTrue);
      expect(data.createdAt.isBefore(after), isTrue);
    });

    test('serializes to a Firestore-compatible map', () {
      final createdAt = DateTime.utc(2026, 8, 5, 12, 0);
      final data = UserDocumentData(
        uid: 'user-456',
        email: 'other@example.com',
        displayName: 'Other User',
        photoURL: null,
        createdAt: createdAt,
      );

      final map = data.toMap();

      expect(map['uid'], 'user-456');
      expect(map['email'], 'other@example.com');
      expect(map['displayName'], 'Other User');
      expect(map['photoURL'], isNull);
      expect(map['xp'], 0);
      expect(map['coins'], 0);
      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate().millisecondsSinceEpoch,
          createdAt.millisecondsSinceEpoch);
    });

    test('handles nullable profile fields', () {
      final user = _FakeUser(uid: 'anon-uid');
      final data = UserDocumentData.fromFirebaseUser(user);

      expect(data.uid, 'anon-uid');
      expect(data.email, isNull);
      expect(data.displayName, isNull);
      expect(data.photoURL, isNull);
      expect(data.xp, 0);
      expect(data.coins, 0);
    });
  });
}
