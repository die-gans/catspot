import 'package:cloud_functions/cloud_functions.dart';

/// Presigned upload slot returned by the backend for a new scan.
class ScanRequest {
  /// Create a [ScanRequest].
  const ScanRequest({required this.scanId, required this.uploadUrl});

  /// Unique identifier for this scan, used later for verification.
  final String scanId;

  /// Presigned URL the client PUTs the JPEG bytes to.
  final String uploadUrl;
}

/// Verdict returned by the backend after image analysis.
class ScanVerdict {
  /// Create a [ScanVerdict].
  const ScanVerdict({
    required this.isRealCat,
    required this.isLivePhoto,
    required this.confidence,
    this.rejectReason,
  });

  /// Whether the image contains a real cat.
  final bool isRealCat;

  /// Whether the image is a live photo (not a screenshot, statue, etc.).
  final bool isLivePhoto;

  /// Confidence reported by the verifier, 0.0–1.0.
  final double confidence;

  /// Human-readable rejection reason, if the scan was rejected.
  final String? rejectReason;
}

/// Provider-agnostic backend contract for the scan pipeline.
///
/// This is the seam that keeps the scan feature independent of any particular
/// backend transport. Implementations may use Firebase Cloud Functions, a
/// custom HTTP API, or a local mock; the caller (the scan verifier) only sees
/// this interface.
abstract interface class CatspotFunctions {
  /// Request a new scan upload slot.
  ///
  /// Returns a [ScanRequest] with a presigned URL that the client PUTs JPEG
  /// bytes to. The backend may require authentication.
  Future<ScanRequest> requestScan();

  /// Verify the uploaded scan identified by [scanId].
  ///
  /// Returns the backend's verdict. The caller decides whether to treat the
  /// scan as approved or rejected.
  Future<ScanVerdict> verifyScan(String scanId);
}

/// Firebase Cloud Functions implementation of [CatspotFunctions].
///
/// Uses callable functions in region `us-central1`. Firebase Auth attaches the
/// signed-in user's ID token automatically, so no manual token bridge is needed.
final class FirebaseCatspotFunctions implements CatspotFunctions {
  /// Create the Firebase implementation.
  ///
  /// [functions] defaults to the Firebase instance for `us-central1`.
  FirebaseCatspotFunctions({FirebaseFunctions? functions})
    : _functions = functions ??
          FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  @override
  Future<ScanRequest> requestScan() async {
    final callable = _functions.httpsCallable('requestScan');
    final result = await callable.call<Map<String, dynamic>>(null);
    final data = _asMap(result.data);
    return ScanRequest(
      scanId: data['scanId'] as String,
      uploadUrl: data['uploadUrl'] as String,
    );
  }

  @override
  Future<ScanVerdict> verifyScan(String scanId) async {
    final callable = _functions.httpsCallable('verifyScan');
    final result = await callable.call<Map<String, dynamic>>({
      'scanId': scanId,
    });
    final data = _asMap(result.data);
    final verdict = _asMap(data['verdict']);
    return ScanVerdict(
      isRealCat: verdict['is_real_cat'] as bool,
      isLivePhoto: verdict['is_live_photo'] as bool,
      confidence: (verdict['confidence'] as num).toDouble(),
      rejectReason: verdict['reject_reason'] as String?,
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (dynamic k, dynamic v) => MapEntry<String, dynamic>(k as String, v),
      );
    }
    throw FormatException('Expected map, got ${value.runtimeType}');
  }
}
