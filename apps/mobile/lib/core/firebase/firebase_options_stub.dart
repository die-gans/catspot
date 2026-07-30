import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Placeholder Firebase options read from dart-defines.
///
/// This stub is used until the real `firebase_options.dart` is generated with the
/// FlutterFire CLI. Pass the values at build/run time with:
///
/// ```
/// --dart-define=FIREBASE_API_KEY=...
/// --dart-define=FIREBASE_APP_ID=...
/// --dart-define=FIREBASE_PROJECT_ID=catspot-9ee0d
/// --dart-define=FIREBASE_SENDER_ID=...
/// ```
///
/// The `FIREBASE_PROJECT_ID` defaults to `catspot-9ee0d` to match the active
/// Firebase project. All other values must be supplied or initialization will be
/// skipped in guarded environments (e.g. tests).
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get _baseOptions {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const projectId = String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'catspot-9ee0d',
    );
    const messagingSenderId = String.fromEnvironment('FIREBASE_SENDER_ID');
    const storageBucket = String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: 'catspot-9ee0d.appspot.com',
    );

    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: '$projectId.firebaseapp.com',
      storageBucket: storageBucket,
    );
  }

  static FirebaseOptions get android => _baseOptions;
  static FirebaseOptions get ios => _baseOptions;
  static FirebaseOptions get macos => _baseOptions;
  static FirebaseOptions get web => _baseOptions;
}
