import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/functions/scan_functions.dart';

/// Result of calling [ScanVerifier.captureAndVerify] and uploading the photo.
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

/// Backend contract for the scan capture + verify flow.
abstract interface class ScanVerifier {
  /// Request a scan slot and upload the captured [imageBytes], then verify.
  ///
  /// Returns [ScanApproved], [ScanRejected], or [ScanFailed] with a visible
  /// message. No silent failures.
  Future<ScanResult> captureAndVerify(Uint8List imageBytes);
}

/// Live verifier that calls backend functions and uploads directly to R2.
final class BackendScanVerifier implements ScanVerifier {
  /// Create the live verifier.
  const BackendScanVerifier({
    required this.functions,
    required this.httpClient,
  });

  /// Backend functions seam; transport-agnostic by design.
  final CatspotFunctions functions;

  /// HTTP client used for the direct R2 PUT upload.
  final http.Client httpClient;

  @override
  Future<ScanResult> captureAndVerify(Uint8List imageBytes) async {
    try {
      final request = await functions.requestScan();

      final upload = await httpClient.put(
        Uri.parse(request.uploadUrl),
        body: imageBytes,
        headers: const {'Content-Type': 'image/jpeg'},
      );

      if (upload.statusCode < 200 || upload.statusCode >= 300) {
        return ScanFailed(
          error: 'Upload failed (${upload.statusCode}): ${upload.body}',
        );
      }

      final verdict = await functions.verifyScan(request.scanId);

      if (verdict.isRealCat && verdict.isLivePhoto) {
        return ScanApproved(confidence: verdict.confidence);
      }
      return ScanRejected(reason: verdict.rejectReason ?? 'Not a real live cat photo');
    } on Exception catch (e, st) {
      return ScanFailed(error: '$e\n$st');
    }
  }
}
