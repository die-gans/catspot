import 'dart:async';
import 'dart:convert';

import 'package:convex_flutter/convex_flutter.dart';

import 'auth_token_provider.dart';

/// Dart-define that points to the Convex deployment. Passed at build/run time
/// via `--dart-define=CONVEX_URL=https://...` (or `--dart-define-from-file`).
const String _kConvexUrl = String.fromEnvironment('CONVEX_URL');

/// Thin wrapper around the [convex_flutter] singleton.
///
/// The wrapper keeps the app decoupled from the package's singleton API so we
/// can swap in a hand-written HTTP client if V1 on-device validation fails.
class CatspotConvexClient {
  const CatspotConvexClient._();

  /// Whether the underlying singleton has been initialized.
  static bool get isInitialized {
    try {
      // Accessing [ConvexClient.instance] throws StateError when not ready.
      ConvexClient.instance;
      return true;
    } on StateError {
      return false;
    }
  }

  /// Stream of WebSocket connection states from the underlying singleton.
  ///
  /// Emits [WebSocketConnectionState.connecting] when the client has not been
  /// initialized, so the validation screen can still render a live line.
  static Stream<WebSocketConnectionState> get connectionState {
    if (!isInitialized) {
      return Stream.value(WebSocketConnectionState.connecting);
    }
    return ConvexClient.instance.connectionState;
  }

  /// Initialize the Convex client from the [_kConvexUrl] dart-define.
  ///
  /// Throws [StateError] if already initialized, and [ArgumentError] if the
  /// deployment URL is missing.
  static Future<void> initialize() async {
    if (_kConvexUrl.isEmpty) {
      throw ArgumentError(
        'CONVEX_URL is not set. '
        'Pass --dart-define=CONVEX_URL=https://<deployment>.convex.cloud',
      );
    }
    await ConvexClient.initialize(
      const ConvexConfig(
        deploymentUrl: _kConvexUrl,
        clientId: 'catspot-mobile',
      ),
    );
  }

  /// Inject a token provider that the Convex client will call for every
  /// authenticated request, including automatic refreshes.
  static Future<AuthHandleWrapper> setAuthTokenProvider(
    AuthTokenProvider tokenProvider, {
    void Function(bool)? onAuthChange,
  }) async {
    return ConvexClient.instance.setAuthWithRefresh(
      fetchToken: tokenProvider,
      onAuthChange: onAuthChange,
    );
  }

  /// Clear any injected auth token and stop the refresh loop.
  static Future<void> clearAuth() async {
    if (isInitialized) {
      await ConvexClient.instance.clearAuth();
    }
  }

  /// Stream of Convex auth state (`true` when authenticated, `false` otherwise).
  static Stream<bool> get authState {
    if (!isInitialized) {
      return Stream.value(false);
    }
    return ConvexClient.instance.authState;
  }

  /// Run a Convex query and return the raw JSON response.
  static Future<String> query(
    String name,
    Map<String, dynamic> args,
  ) async {
    _assertInitialized();
    return ConvexClient.instance.query(name, args);
  }

  /// Run a Convex mutation and return the raw JSON response.
  static Future<String> mutation(
    String name,
    Map<String, dynamic> args,
  ) async {
    _assertInitialized();
    return ConvexClient.instance.mutation(name: name, args: args);
  }

  /// Run a Convex action and return the raw JSON response.
  static Future<String> action(
    String name,
    Map<String, dynamic> args,
  ) async {
    _assertInitialized();
    return ConvexClient.instance.action(name: name, args: args);
  }

  /// Subscribe to a Convex query. Returns a handle that can be cancelled.
  static Future<SubscriptionHandle> subscribe({
    required String name,
    required Map<String, dynamic> args,
    required void Function(String) onUpdate,
    required void Function(String, String?) onError,
  }) async {
    _assertInitialized();
    return ConvexClient.instance.subscribe(
      name: name,
      args: args,
      onUpdate: onUpdate,
      onError: onError,
    );
  }

  /// Parse a Convex JSON response into a Dart object.
  ///
  /// Returns `null` when the backend returns JSON `null`.
  static T? decode<T>(String json, T Function(Object?) fromJson) {
    final dynamic data = jsonDecode(json);
    if (data == null) {
      return null;
    }
    return fromJson(data);
  }

  static void _assertInitialized() {
    if (!isInitialized) {
      throw StateError(
        'CatspotConvexClient is not initialized. Call initialize() first.',
      );
    }
  }
}

/// Handle returned by [CatspotConvexClient.setAuthTokenProvider].
///
/// This re-exports the underlying [AuthHandleWrapper] so callers can dispose
/// of the refresh loop without importing `convex_flutter` directly.
typedef ConvexAuthHandle = AuthHandleWrapper;
