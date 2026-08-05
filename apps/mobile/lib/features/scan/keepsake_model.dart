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

  factory Keepsake.fromJson(Map<String, dynamic> json) {
    return Keepsake(
      id: json['_id'] as String,
      name: json['name'] as String,
      cutoutUrl: (json['cutoutUrl'] ?? json['imageUrl']) as String,
      serialNumber: json['serialNumber'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num).toInt(),
      ),
    );
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
}
