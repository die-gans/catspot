import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/convex/catspot_convex_client.dart';
import '../../core/firebase/firebase_token_bridge.dart';
import '../../core/theme/theme.dart';

/// V1/V2 on-device validation harness.
///
/// Displays live status lines for the Convex client, the Firebase auth state
/// (signed in/out + uid), whether a Firebase ID token was obtained, and the
/// result of calling `users:current`.
class ValidationScreen extends StatefulWidget {
  /// Create a validation screen.
  const ValidationScreen({super.key});

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  late final Stream<String> _connectionState;
  late final Stream<User?> _authState;

  Future<String>? _tokenFuture;
  Future<String>? _userFuture;

  @override
  void initState() {
    super.initState();
    _authState = FirebaseAuth.instance.authStateChanges();
    _connectionState = CatspotConvexClient.connectionState
        .map((state) => state.name)
        .handleError((_) => 'unknown');
    _poll();
  }

  void _poll() {
    _tokenFuture = _fetchToken();
    _userFuture = _fetchUser();
  }

  Future<String> _fetchToken() async {
    try {
      final token = await firebaseTokenBridge(forceRefresh: true)();
      if (token == null || token.isEmpty) {
        return 'none';
      }
      return 'obtained (${token.length} chars)';
    } on Exception catch (e) {
      return 'error: $e';
    }
  }

  Future<String> _fetchUser() async {
    try {
      if (!CatspotConvexClient.isInitialized) {
        return 'Convex client not initialized';
      }
      final result = await CatspotConvexClient.query('users:current', {});
      return 'success: $result';
    } on Exception catch (e) {
      return 'error: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CatspotTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('V1/V2 Validation')),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacing.space4),
        children: [
          _StatusLine(
            label: 'Convex initialized',
            value: CatspotConvexClient.isInitialized ? 'Y' : 'N',
          ),
          _StatusStreamLine(
            label: 'Convex connection',
            stream: _connectionState,
          ),
          _StatusStreamLine(
            label: 'Firebase auth state',
            stream: _authState
                .map((user) {
                  if (user == null) return 'signed out';
                  return 'signed in: ${user.uid}';
                })
                .handleError((_) => 'unknown'),
          ),
          _StatusFutureLine(label: 'Firebase ID token', future: _tokenFuture),
          _StatusFutureLine(label: 'users:current', future: _userFuture),
          SizedBox(height: tokens.spacing.space4),
          ElevatedButton(
            onPressed: () => setState(_poll),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(label: label, child: Text(value));
  }
}

class _StatusStreamLine extends StatelessWidget {
  const _StatusStreamLine({required this.label, required this.stream});

  final String label;
  final Stream<String> stream;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      label: label,
      child: StreamBuilder<String>(
        stream: stream,
        builder: (context, snapshot) => Text(snapshot.data ?? '…'),
      ),
    );
  }
}

class _StatusFutureLine extends StatelessWidget {
  const _StatusFutureLine({required this.label, required this.future});

  final String label;
  final Future<String>? future;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      label: label,
      child: FutureBuilder<String>(
        future: future,
        builder: (context, snapshot) => Text(snapshot.data ?? '…'),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = CatspotTheme.of(context);
    return Card(
      margin: EdgeInsets.only(bottom: tokens.spacing.space3),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: tokens.typography.label),
            SizedBox(height: tokens.spacing.space2),
            child,
          ],
        ),
      ),
    );
  }
}
