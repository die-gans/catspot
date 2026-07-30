import 'package:catspot_mobile/app.dart';
import 'package:catspot_mobile/core/convex/catspot_convex_client.dart';
import 'package:catspot_mobile/core/firebase/firebase_options_stub.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'router.dart';

/// Whether the Firebase dart-defines required to initialize the app are present.
bool get _kFirebaseConfigured {
  return const String.fromEnvironment('FIREBASE_API_KEY').isNotEmpty &&
      const String.fromEnvironment('FIREBASE_APP_ID').isNotEmpty;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_kFirebaseConfigured) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    bindFirebaseAuthNotifier();
  } else {
    debugPrint(
      'Firebase not initialized: missing FIREBASE_API_KEY / FIREBASE_APP_ID '
      'dart-defines. This is expected in test environments.',
    );
  }

  await CatspotConvexClient.initialize();
  runApp(const CatspotApp());
}
