import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'cat_detection_models.dart';
import 'scan_controller.dart';
import 'scan_providers.dart';
import 'scan_verifier.dart';

/// Debug scan screen that exercises the iOS Vision cat detector and the Convex
/// scan-verify flow.
///
/// Reachable at `/debug/scan`. This is intentionally behind a debug route and
/// not part of the main user flow.
class ScanScreen extends ConsumerStatefulWidget {
  /// Create the scan screen.
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scanControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Debug'),
        actions: [
          TextButton(
            onPressed: () => context.go('/debug/validation'),
            child: const Text('Validation'),
          ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ScanState state) {
    if (state.isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.controller == null) {
      return _ErrorView(message: state.error!);
    }

    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const _ErrorView(message: 'Camera not initialized');
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              _BoundingBoxOverlay(detections: state.detections),
              _StatusOverlay(
                detections: state.detections,
                isCaptureEnabled: state.isCaptureEnabled,
              ),
            ],
          ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (state.lastResult != null)
          _ResultBanner(result: state.lastResult!),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isCaptureEnabled && !state.isCapturing
                  ? () => ref.read(scanControllerProvider.notifier).capture()
                  : null,
              child: state.isCapturing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Capture Cat'),
            ),
          ),
        ),
      ],
    );
  }
}

class _BoundingBoxOverlay extends StatelessWidget {
  const _BoundingBoxOverlay({required this.detections});

  final List<CatDetection> detections;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _BoundingBoxPainter(
            detections: detections,
            previewSize: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        );
      },
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  _BoundingBoxPainter({
    required this.detections,
    required this.previewSize,
  });

  final List<CatDetection> detections;
  final Size previewSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.greenAccent;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final detection in detections) {
      final normalized = detection.boundingBox.toFlutterRect();
      final rect = Rect.fromLTWH(
        normalized.left * previewSize.width,
        normalized.top * previewSize.height,
        normalized.width * previewSize.width,
        normalized.height * previewSize.height,
      );
      canvas.drawRect(rect, paint);

      textPainter.text = TextSpan(
        text:
            '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black54,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, rect.topLeft);
    }
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.previewSize != previewSize;
  }
}

class _StatusOverlay extends StatelessWidget {
  const _StatusOverlay({
    required this.detections,
    required this.isCaptureEnabled,
  });

  final List<CatDetection> detections;
  final bool isCaptureEnabled;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detections: ${detections.length}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              isCaptureEnabled ? 'Capture enabled' : 'Looking for cat…',
              style: TextStyle(
                color: isCaptureEnabled ? Colors.greenAccent : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result});

  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (result) {
      ScanApproved() => (
          Colors.green.shade100,
          Colors.green.shade900,
        ),
      ScanRejected() => (
          Colors.red.shade100,
          Colors.red.shade900,
        ),
      ScanFailed() => (
          Colors.orange.shade100,
          Colors.orange.shade900,
        ),
    };

    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              result.message,
              style: TextStyle(color: foreground, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Reading the notifier in a button callback is safe here.
              final container = ProviderScope.containerOf(context);
              container.read(scanControllerProvider.notifier).clearResult();
            },
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final container = ProviderScope.containerOf(context);
                container.read(scanControllerProvider.notifier).initialize();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
