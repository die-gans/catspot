import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/functions/functions_providers.dart';
import 'cat_detection_service.dart';
import 'keepsake_service.dart';
import 'scan_controller.dart';

export '../../core/functions/functions_providers.dart' show catspotFunctionsProvider;

final catDetectionServiceProvider = Provider<CatDetectionService>(
  (ref) => MethodChannelCatDetectionService(),
);

final keepsakeServiceProvider = Provider<KeepsakeService>(
  (ref) => KeepsakeService(functions: ref.watch(catspotFunctionsProvider)),
);

final scanControllerProvider = StateNotifierProvider<ScanController, ScanState>(
  (ref) => ScanController(
    detectionService: ref.watch(catDetectionServiceProvider),
    keepsakeService: ref.watch(keepsakeServiceProvider),
  ),
);
