import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/convex/catspot_convex_client.dart';

/// Result of calling [ScanVerifier.requestScan] and uploading the photo.
sealed class ScanResult {
  /// Human-readable message suitable for a snack bar or status line.
  String get message;
}

/// Scan was approved by the backend verifier.
final class ScanApproved extends ScanResult {
  /// Create an approved result.
  ScanApproved({required this.confidence});

  /// Confidence reported by the backend verifier.
  final double confidence;

  @override
  String get message => 'Approved! confidence: ${(confidence * 100).toStringAsFixed(0)}%';
}

/// Scan was rejected by the backend verifier.
final class ScanRejected extends ScanResult {
  /// Create a rejected result.
  ScanRejected({required this.reason});

  /// Rejection reason returned by the backend, if any.
  final String? reason;

  @override
  String get message => 'Rejected${reason != null && reason!.isNotEmpty ? ': $reason' : ''}';
}

/// Something went wrong before or during verification.
final class ScanFailed extends ScanResult {
  /// Create a failed result.
  ScanFailed({required this.error});

  /// The underlying error message.
  final String error;

  @override
  String get message => 'Error: $error';
}

/// Verdict returned by the `scans:verify` Convex action.
typedef ScanVerdict = ({bool isRealCat, bool isLivePhoto, double confidence, String? rejectReason});

/// Backend contract for the scan capture + verify flow.
abstract interface class ScanVerifier {
  /// Request a scan slot and upload the captured [imageBytes], then verify.
  ///
  /// Returns [ScanApproved], [ScanRejected], or [ScanFailed] with a visible
  /// message. No silent failures.
  Future<ScanResult> captureAndVerify(Uint8List imageBytes);
}

/// Live verifier that calls Convex actions and uploads directly to R2.
final class ConvexScanVerifier implements ScanVerifier {
  /// Create the live verifier.
  const ConvexScanVerifier({
    required this.httpClient,
  });

  /// HTTP client used for the direct R2 PUT upload.
  final http.Client httpClient;

  @override
  Future<ScanResult> captureAndVerify(Uint8List imageBytes) async {
    try {
      final requestResponse = await CatspotConvexClient.action(
        'scans:requestScan',
        const {},
      );
      final requestData = jsonDecode(requestResponse) as Map<String, dynamic>;
      final scanId = requestData['scanId'] as String;
      final uploadUrl = requestData['uploadUrl'] as String;

      final upload = await httpClient.put(
        Uri.parse(uploadUrl),
        body: imageBytes,
        headers: const {'Content-Type': 'image/jpeg'},
      );

      if (upload.statusCode < 200 || upload.statusCode >= 300) {
        return ScanFailed(
          error: 'Upload failed (${upload.statusCode}): ${upload.body}',
        );
      }

      final verifyResponse = await CatspotConvexClient.action(
        'scans:verify',
        {'scanId': scanId},
      );
      final verifyData = jsonDecode(verifyResponse) as Map<String, dynamic>;
      final verdict = verifyData['verdict'] as Map<String, dynamic>;

      final isRealCat = verdict['is_real_cat'] as bool;
      final isLivePhoto = verdict['is_live_photo'] as bool;
      final confidence = (verdict['confidence'] as num).toDouble();
      final rejectReason = verdict['reject_reason'] as String?;

      if (isRealCat && isLivePhoto) {
        return ScanApproved(confidence: confidence);
      }
      return ScanRejected(reason: rejectReason ?? 'Not a real live cat photo');
    } on Exception catch (e, st) {
      return ScanFailed(error: '$e\n$st');
    }
  }
}
