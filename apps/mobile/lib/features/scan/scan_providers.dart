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

final scanControllerProvider = StateNotifierProvider<ScanController, ScanState>(
  (ref) => ScanController(
    detectionService: ref.watch(catDetectionServiceProvider),
    keepsakeService: ref.watch(keepsakeServiceProvider),
  ),
);
