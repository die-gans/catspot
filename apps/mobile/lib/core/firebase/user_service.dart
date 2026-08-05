import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Client-side fallback for ensuring a `users/{uid}` document exists.
///
/// The backend's `onCreate` auth trigger is the primary creator; this service
/// exists so the doc is present even if the trigger is delayed or fails.
@immutable
class UserDocumentData {
  const UserDocumentData({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.xp = 0,
    this.coins = 0,
    required this.createdAt,
  });

  factory UserDocumentData.fromFirebaseUser(User user) {
    return UserDocumentData(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      createdAt: DateTime.now().toUtc(),
    );
  }

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final int xp;
  final int coins;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'xp': xp,
        'coins': coins,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Ensures the user document exists, creating it only when absent.
  ///
  /// Returns `true` if a document was created, `false` if it already existed.
  Future<bool> ensureUserDoc(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) return false;

    final data = UserDocumentData.fromFirebaseUser(user);
    await docRef.set(data.toMap());
    return true;
  }
}
