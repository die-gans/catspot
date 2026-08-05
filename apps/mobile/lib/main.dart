import 'dart:async';

import 'package:catspot_mobile/app.dart';
import 'package:catspot_mobile/core/startup/startup_error.dart';
import 'package:catspot_mobile/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'router.dart';

const _startupTag = '[catspot-startup]';

/// Replace the entire app with a visible error surface.
///
/// Called from the zone error handler, [FlutterError.onError], and anywhere else
/// an uncaught failure would otherwise leave a blank white screen. [runApp] is
/// idempotent, so this is safe whether or not [CatspotApp] has already been
/// mounted.
void _showFatalError(Object error, StackTrace? stackTrace) {
  final message = error.toString();
  debugPrint('$_startupTag FATAL: $message');
  if (stackTrace != null) {
    debugPrint('$_startupTag STACK: $stackTrace');
  }
  runApp(StartupErrorApp(error: message, stackTrace: stackTrace));
}

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Ensure every framework/layout error becomes visible in release mode,
      // not a white screen or grey/red debug box that only appears in debug.
      ErrorWidget.builder = (FlutterErrorDetails details) {
        debugPrint('$_startupTag ErrorWidget: ${details.exception}');
        return MaterialApp(
          home: Scaffold(
            body: StartupErrorBody(
              error: details.exception.toString(),
              stackTrace: details.stack,
            ),
          ),
        );
      };

      FlutterError.onError = (FlutterErrorDetails details) {
        debugPrint(
          '$_startupTag FlutterError: ${details.exception}',
        );
        if (details.stack != null) {
          debugPrint('$_startupTag FlutterError stack: ${details.stack}');
        }
        // Replace the whole app with the startup error surface so the user
        // always sees what happened, even in release builds.
        _showFatalError(details.exception, details.stack);
      };

      String? startupError;
      StackTrace? startupStackTrace;

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('$_startupTag Firebase initialized');
        bindFirebaseAuthNotifier();
      } catch (e, st) {
        startupError = 'Firebase initialization failed: $e';
        startupStackTrace = st;
        debugPrint('$_startupTag Firebase init failed: $e');
        debugPrint('$_startupTag $st');
      }

      // Always call runApp, even when startup partially fails. A visible error
      // screen is infinitely better than a blank white screen on a device.
      if (startupError != null) {
        runApp(StartupErrorApp(error: startupError, stackTrace: startupStackTrace));
      } else {
        runApp(const CatspotApp());
      }
    },
    (Object error, StackTrace stackTrace) {
      // Catches async errors that escape the main zone (unawaited futures,
      // release-only plugin failures, etc.). Replaces whatever is currently
      // rendered with the error surface so the white screen is impossible.
      _showFatalError(error, stackTrace);
    },
  );
}
