import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/firebase/firebase_auth_gate.dart';
import 'core/theme/theme.dart';
import 'features/debug/validation_screen.dart';

/// Notifies [GoRouter] when Firebase auth state changes so redirects re-evaluate.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier([Stream<bool?>? stream]) {
    if (stream != null) setStream(stream);
  }

  StreamSubscription<bool?>? _sub;

  void setStream(Stream<bool?> stream) {
    _sub?.cancel();
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Auth-state notifier used by the router.
///
/// The stream is wired to [FirebaseAuth.instance.authStateChanges] in
/// [main.dart] once Firebase is initialized. Until then the router treats the
/// user as signed out, which is safe for test environments without Firebase.
final _authNotifier = _AuthNotifier();

/// Wire the router auth notifier to the live Firebase auth stream.
///
/// This is called from [main.dart] only when Firebase is initialized. It is a
/// no-op if the notifier already has a stream.
void bindFirebaseAuthNotifier() {
  try {
    final stream = FirebaseAuth.instance.authStateChanges().map(
      (user) => user != null,
    );
    _authNotifier.setStream(stream);
  } on Exception {
    // Keep the router in the signed-out fallback when Firebase is unavailable.
  }
}

/// App router.
///
/// Redirects enforce the Firebase auth gate: signed-out users land on
/// `/sign-in`, signed-in users are kept away from the auth route.
final GoRouter router = GoRouter(
  initialLocation: '/',
  refreshListenable: _authNotifier,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const FirebaseAuthGate(home: _HomePlaceholder()),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const _SignInScreen(),
    ),
    GoRoute(
      path: '/debug/validation',
      builder: (context, state) => const ValidationScreen(),
    ),
  ],
  redirect: (context, state) {
    final isSignedIn = _firebaseSignedIn();
    final location = state.matchedLocation;

    final isAuthRoute = location == '/sign-in';

    if (!isSignedIn && !isAuthRoute) {
      return '/sign-in';
    }
    if (isSignedIn && isAuthRoute) {
      return '/';
    }
    return null;
  },
);

bool _firebaseSignedIn() {
  try {
    return FirebaseAuth.instance.currentUser != null;
  } on Exception {
    // Firebase is not initialized (e.g. test environment). Treat as signed out.
    return false;
  }
}

/// Home placeholder shown once the user is authenticated.
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catspot')),
      body: const Center(child: Text('Home')),
    );
  }
}

/// Sign-in screen rendered by the `/sign-in` route.
///
/// Minimal email + password form backed by Firebase Auth. Apple/Google SSO
/// buttons are deferred to a later platform-configuration card.
class _SignInScreen extends StatefulWidget {
  const _SignInScreen();

  @override
  State<_SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<_SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final auth = FirebaseAuth.instance;
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_isSignUp) {
        await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } on Exception catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<CatspotTokens>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in to Catspot')),
      body: Padding(
        padding: EdgeInsets.all(tokens?.spacing.space4 ?? 16),
        child: ListView(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
            ),
            SizedBox(height: tokens?.spacing.space3 ?? 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: tokens?.spacing.space3 ?? 12),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              SizedBox(height: tokens?.spacing.space3 ?? 12),
            ],
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: Text(_isSignUp ? 'Create account' : 'Sign in'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() => _isSignUp = !_isSignUp),
              child: Text(
                _isSignUp
                    ? 'Already have an account? Sign in'
                    : 'Create account',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
