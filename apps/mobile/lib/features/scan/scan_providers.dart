import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cat_detection_service.dart';
import 'keepsake_service.dart';
import 'scan_controller.dart';

final catDetectionServiceProvider = Provider<CatDetectionService>(
  (ref) => MethodChannelCatDetectionService(),
);

final keepsakeServiceProvider = Provider<KeepsakeService>(
  (ref) => KeepsakeService(),
);

/// Auto-disposed when the scan route is left so a stale capture/isolated
/// image or keepsake cannot leak into the next session. Re-entering the route
/// creates a fresh controller with a clean [ScanState].
final scanControllerProvider = StateNotifierProvider.autoDispose<ScanController, ScanState>(
  (ref) => ScanController(
    detectionService: ref.watch(catDetectionServiceProvider),
    keepsakeService: ref.watch(keepsakeServiceProvider),
  ),
);
