import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'keepsake_model.dart';

class KeepsakeService {
  KeepsakeService({
    FirebaseFunctions? firebaseFunctions,
    http.Client? httpClient,
  })  : _firebase = firebaseFunctions ??
            FirebaseFunctions.instanceFor(region: 'us-central1'),
        _http = httpClient ?? http.Client();

  final FirebaseFunctions _firebase;

  // Retained as an injectable seam even though the single-call fast path no
  // longer uploads directly to R2. Keeping it avoids breaking existing tests
  // and allows future flows to swap back in.
  // ignore: unused_field
  final http.Client _http;

  static const _galleryChannel = MethodChannel('catspot/gallery');

  Future<Keepsake> saveAndCreate(Uint8List png) async {
    // Single-call fast path: upload + create record in one Cloud Function.
    final callable = _firebase.httpsCallable('catchKeepsake');
    final result = await callable.call<Map<Object?, Object?>>({
      'pngBase64': base64Encode(png),
    });
    final data = _asMap(result.data);
    final keepsake = Keepsake.fromJson(data);

    // Save PNG to device Photos library (best-effort) — don't block the result.
    unawaited(_saveToGallery(png));

    return keepsake;
  }

  Future<List<Keepsake>> list() async {
    final callable = _firebase.httpsCallable('listKeepsakes');
    final result = await callable.call<List<Object?>>(null);
    final raw = result.data;
    return raw
        .cast<Map<Object?, Object?>>()
        .map((m) => Keepsake.fromJson(_asMap(m)))
        .toList(growable: false);
  }

  Future<void> _saveToGallery(Uint8List png) async {
    try {
      await _galleryChannel.invokeMethod<bool>('saveImage', png);
    } on Exception {
      // Ignored — don't fail the flow if Photos is denied or unavailable.
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (dynamic k, dynamic v) => MapEntry<String, dynamic>(k as String, v),
      );
    }
    throw FormatException('Expected map, got ${value.runtimeType}');
  }
}
