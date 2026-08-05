import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'scan_functions.dart';

/// Live Firebase Cloud Functions backend for the scan pipeline.
///
/// Overridable in tests by supplying a [CatspotFunctions] implementation via
/// [ProviderContainer] overrides.
final catspotFunctionsProvider = Provider<CatspotFunctions>(
  (ref) => FirebaseCatspotFunctions(),
);
