import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'cat_detection_service.dart';
import 'scan_controller.dart';
import 'scan_verifier.dart';

/// Default HTTP client for scan uploads.
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

/// Detection service used by the scan screen.
///
/// Returns a stub on unsupported platforms so the app still runs.
final catDetectionServiceProvider = Provider<CatDetectionService>(
  (ref) => MethodChannelCatDetectionService(),
);

/// Backend verifier for the capture flow.
final scanVerifierProvider = Provider<ScanVerifier>((ref) {
  final client = ref.watch(httpClientProvider);
  return ConvexScanVerifier(httpClient: client);
});

/// State controller for the scan debug screen.
final scanControllerProvider = StateNotifierProvider<ScanController, ScanState>(
  (ref) {
    final detectionService = ref.watch(catDetectionServiceProvider);
    final verifier = ref.watch(scanVerifierProvider);
    return ScanController(
      detectionService: detectionService,
      verifier: verifier,
    );
  },
);
