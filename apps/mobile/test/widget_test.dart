import 'dart:async';

import 'package:catspot_mobile/core/firebase/firebase_auth_gate.dart';
import 'package:catspot_mobile/core/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Catspot light theme resolves CatspotColors and tokens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: catspotLightThemeData(),
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    final BuildContext context = tester.element(find.byType(Scaffold));
    final CatspotColors? colors = Theme.of(context).extension<CatspotColors>();
    final CatspotTokens? tokens = Theme.of(context).extension<CatspotTokens>();

    expect(colors, isNotNull);
    expect(tokens, isNotNull);
    expect(colors!.brandPrimary, const Color(0xFFE86A33));
    expect(CatspotTheme.of(context).colors.brandPrimary, colors.brandPrimary);
  });

  testWidgets(
    'FirebaseAuthGate renders a loading shell before auth state resolves',
    (WidgetTester tester) async {
      final controller = StreamController<User?>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: FirebaseAuthGate(
            home: const Text('HOME'),
            authStateChanges: controller.stream,
          ),
        ),
      );

      // No auth event yet: the gate shows the loading shell, not home.
      expect(find.text('HOME'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );
}
