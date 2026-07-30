import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';
import 'router.dart';

/// Root MaterialApp for Catspot.
class CatspotApp extends StatelessWidget {
  const CatspotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'Catspot',
        theme: catspotLightThemeData(),
        routerConfig: router,
      ),
    );
  }
}
