import 'dart:async';

import 'package:catspot_mobile/core/firebase/firebase_auth_gate.dart';
import 'package:catspot_mobile/core/startup/startup_error.dart';
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

  group('FirebaseAuthGate', () {
    testWidgets(
      'renders branded loading shell before auth state resolves',
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

        // No auth event yet: the gate shows the branded loading shell, not home.
        expect(find.text('HOME'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Catspot'), findsOneWidget);
      },
    );

    testWidgets(
      'renders home when auth stream emits a signed-in user',
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

        final user = _FakeUser();
        controller.add(user);
        await tester.pump();

        expect(find.text('HOME'), findsOneWidget);
      },
    );

    testWidgets(
      'renders timeout retry surface when auth stalls for 10s',
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

        // Initially loading.
        expect(find.text('HOME'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for the 10s timeout.
        await tester.pump(const Duration(seconds: 10));

        expect(find.text('Sign-in check is taking too long'), findsOneWidget);
        expect(find.text('Check your connection and try again.'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
      },
    );

    testWidgets(
      'retry after timeout returns to branded loading state',
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

        await tester.pump(const Duration(seconds: 10));
        expect(find.text('Sign-in check is taking too long'), findsOneWidget);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
        await tester.pump();

        expect(find.text('Sign-in check is taking too long'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });

  group('StartupErrorBody', () {
    testWidgets('renders the provided error message', (WidgetTester tester) async {
      const errorMessage = 'Firebase initialization failed: test error';

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StartupErrorBody(error: errorMessage))),
      );

      expect(find.text('Catspot could not start'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('renders the provided stack trace when present', (WidgetTester tester) async {
      const errorMessage = 'Something went wrong';
      final stackTrace = StackTrace.current;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StartupErrorBody(error: errorMessage, stackTrace: stackTrace),
          ),
        ),
      );

      expect(find.text('Catspot could not start'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text(stackTrace.toString()), findsOneWidget);
    });
  });

  group('StartupErrorApp', () {
    testWidgets('renders as a standalone app with the error', (WidgetTester tester) async {
      const errorMessage = 'Startup failed';

      await tester.pumpWidget(
        const StartupErrorApp(error: errorMessage),
      );

      expect(find.text('Catspot could not start'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
    });
  });
}

class _FakeUser extends Fake implements User {
  @override
  String? get displayName => 'Test User';

  @override
  String? get email => 'test@example.com';

  @override
  String get uid => 'fake-uid';
}
