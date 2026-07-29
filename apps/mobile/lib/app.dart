import 'package:catspot_mobile/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Root MaterialApp for Catspot.
/// Router configuration will be wired here in a later scaffold card.
class CatspotApp extends StatelessWidget {
  const CatspotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catspot',
      theme: catspotLightThemeData(),
      home: const Scaffold(body: Center(child: Text('Catspot'))),
    );
  }
}
