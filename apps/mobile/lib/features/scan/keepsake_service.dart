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
  final http.Client _http;

  static const _galleryChannel = MethodChannel('catspot/gallery');

  Future<Keepsake> saveAndCreate(Uint8List png) async {
    // 1. Get presigned upload URL.
    final uploadCallable = _firebase.httpsCallable('requestCutoutUpload');
    final uploadResult =
        await uploadCallable.call<Map<Object?, Object?>>(null);
    final uploadData = _asMap(uploadResult.data);
    final uploadUrl = uploadData['uploadUrl'] as String;
    final r2Key = uploadData['r2Key'] as String;

    // 2. PUT the PNG directly to R2.
    final putResponse = await _http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': 'image/png'},
      body: png,
    );
    if (putResponse.statusCode != 200) {
      throw Exception('R2 upload failed: ${putResponse.statusCode}');
    }

    // 3. Create keepsake record (Gemini naming server-side).
    final createCallable = _firebase.httpsCallable('createKeepsake');
    final createResult =
        await createCallable.call<Map<Object?, Object?>>({'r2Key': r2Key});
    final createData = _asMap(createResult.data);
    final keepsake = Keepsake.fromJson(createData);

    // 4. Save PNG to device Photos library (best-effort).
    try {
      await _galleryChannel.invokeMethod<bool>('saveImage', png);
    } on PlatformException {
      // Ignored — don't fail the flow if Photos is denied.
    }

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
