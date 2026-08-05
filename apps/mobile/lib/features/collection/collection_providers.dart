import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../scan/keepsake_model.dart';

/// Maps Firestore document data to [Keepsake] objects.
///
/// Split out so stream mapping can be unit-tested without a real Firestore
/// client.
class KeepsakeStreamMapper {
  const KeepsakeStreamMapper._();

  static List<Keepsake> fromDocs(
    List<({String id, Map<String, dynamic> data})> docs,
  ) {
    return docs
        .map((doc) => Keepsake.fromFirestore(doc.id, doc.data))
        .toList(growable: false);
  }
}

/// Live stream of the current user's keepsakes from Firestore.
///
/// New catches appear automatically once the backend creates the document and
/// the client has permission to read it. This relies on the Firestore rules
/// deployed by the backend PR — merge this PR AFTER that one.
final keepsakeStreamProvider = StreamProvider<List<Keepsake>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(<Keepsake>[]);

  return FirebaseFirestore.instance
      .collection('keepsakes')
      .where('uid', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return KeepsakeStreamMapper.fromDocs(
      snapshot.docs.map((doc) => (id: doc.id, data: doc.data())).toList(),
    );
  });
});
