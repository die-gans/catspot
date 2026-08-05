import 'package:catspot_mobile/app.dart';
import 'package:catspot_mobile/core/startup/startup_error.dart';
import 'package:catspot_mobile/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? startupError;
  StackTrace? startupStackTrace;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    bindFirebaseAuthNotifier();
  } catch (e, st) {
    startupError = 'Firebase initialization failed: $e';
    startupStackTrace = st;
  }

  // Always call runApp, even when startup partially fails. A visible error
  // screen is infinitely better than a blank white screen on a device.
  if (startupError != null) {
    runApp(StartupErrorApp(error: startupError, stackTrace: startupStackTrace));
  } else {
    runApp(const CatspotApp());
  }
}
