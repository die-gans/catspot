import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class Keepsake {
  const Keepsake({
    required this.id,
    required this.name,
    required this.cutoutUrl,
    required this.serialNumber,
    required this.createdAt,
  });

  /// Tolerant parser used by both Cloud Functions responses and direct
  /// Firestore documents.
  ///
  /// Accepts `id` or `_id`, `cutoutUrl` or `imageUrl`, and `createdAt` as an
  /// epoch millis integer, a Firestore [Timestamp], a [DateTime], or an
  /// ISO-8601 string.
  factory Keepsake.fromJson(Map<String, dynamic> json) {
    return Keepsake(
      id: (json['id'] ?? json['_id']) as String,
      name: json['name'] as String,
      cutoutUrl: (json['cutoutUrl'] ?? json['imageUrl']) as String,
      serialNumber: json['serialNumber'] as String,
      createdAt: _parseCreatedAt(json['createdAt']),
    );
  }

  /// Parses a Firestore document, using [docId] as [id].
  factory Keepsake.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    return Keepsake.fromJson(<String, dynamic>{...data, 'id': docId});
  }

  final String id;
  final String name;
  final String cutoutUrl;
  final String serialNumber;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'cutoutUrl': cutoutUrl,
        'serialNumber': serialNumber,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  static DateTime _parseCreatedAt(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
