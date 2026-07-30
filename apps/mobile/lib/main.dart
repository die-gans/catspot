import 'package:catspot_mobile/app.dart';
import 'package:catspot_mobile/core/convex/catspot_convex_client.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CatspotConvexClient.initialize();
  runApp(const CatspotApp());
}
