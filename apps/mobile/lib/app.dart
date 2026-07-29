import 'package:flutter/material.dart';

/// Root MaterialApp for Catspot.
/// Router configuration will be wired here in a later scaffold card.
class CatspotApp extends StatelessWidget {
  const CatspotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catspot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('Catspot'))),
    );
  }
}
