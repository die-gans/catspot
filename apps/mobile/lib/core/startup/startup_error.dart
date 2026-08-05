import 'package:flutter/material.dart';

/// Lightweight fallback app rendered when startup fails before the first frame.
///
/// This replaces the default white screen with the actual error message so
/// on-device failures are diagnosable without a debugger. It is intentionally
/// plain (no Catspot theme dependencies) because the theme may not have loaded.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({required this.error, this.stackTrace, super.key});

  /// Human-readable startup error.
  final String error;

  /// Optional stack trace captured at the failure point.
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catspot',
      home: Scaffold(body: StartupErrorBody(error: error, stackTrace: stackTrace)),
    );
  }
}

/// Reusable error surface used by [StartupErrorApp], [ErrorWidget.builder], and
/// the startup zone handler.
///
/// Works in release mode (no debug-only banners) and never depends on app theme
/// having loaded successfully.
class StartupErrorBody extends StatelessWidget {
  const StartupErrorBody({required this.error, this.stackTrace, super.key});

  /// Human-readable error.
  final String error;

  /// Optional stack trace captured at the failure point.
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Catspot could not start',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    error,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
            if (stackTrace != null) ...[
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      stackTrace.toString(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
