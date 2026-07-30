import 'package:catspot_mobile/app.dart';
import 'package:catspot_mobile/core/convex/catspot_convex_client.dart';
import 'package:catspot_mobile/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  bindFirebaseAuthNotifier();

  await CatspotConvexClient.initialize();
  runApp(const CatspotApp());
}
