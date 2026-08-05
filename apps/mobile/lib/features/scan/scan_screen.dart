import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'cat_detection_models.dart';
import 'keepsake_model.dart';
import 'scan_controller.dart';
import 'scan_providers.dart';

class ScanScreen extends ConsumerStatefulWidget {
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
      appBar: state.keepsake == null
          ? AppBar(title: const Text('Scan'))
          : null,
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

    // Catch result — keepsake successfully created.
    if (state.keepsake != null) {
      return _CatchResult(
        keepsake: state.keepsake!,
        isolatedBytes: state.isolatedBytes,
        onScanAgain: () => ref.read(scanControllerProvider.notifier).retake(),
      );
    }

    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const _ErrorView(message: 'Camera not initialized');
    }

    // Isolation complete → sticker preview with "Catch!" button.
    if (state.isolatedBytes != null) {
      return _StickerPreview(
        isolatedBytes: state.isolatedBytes!,
        isBusy: state.isCreatingKeepsake,
        onCatch: () => ref.read(scanControllerProvider.notifier).catchIt(),
        onRetake: () => ref.read(scanControllerProvider.notifier).retake(),
      );
    }

    final captured = state.capturedBytes;
    final busy = state.isCapturing || state.isIsolating;

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (captured != null)
                _StillImage(bytes: captured)
              else
                CameraPreview(controller),
              _BoundingBoxOverlay(detections: state.detections),
              if (busy)
                const ColoredBox(
                  color: Color(0x55000000),
                  child: Center(child: CircularProgressIndicator()),
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
        if (!busy)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: captured == null
                  ? FilledButton(
                      onPressed: state.isCaptureEnabled
                          ? () => ref.read(scanControllerProvider.notifier).capture()
                          : null,
                      child: const Text('Take Photo'),
                    )
                  : OutlinedButton(
                      onPressed: () =>
                          ref.read(scanControllerProvider.notifier).retake(),
                      child: const Text('Retake'),
                    ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sticker preview — shown after background removal, before keepsake creation
// ---------------------------------------------------------------------------

class _StickerPreview extends StatelessWidget {
  const _StickerPreview({
    required this.isolatedBytes,
    required this.isBusy,
    required this.onCatch,
    required this.onRetake,
  });

  final Uint8List isolatedBytes;
  final bool isBusy;
  final VoidCallback onCatch;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _CheckerboardPainter(),
            child: Center(
              child: Image.memory(isolatedBytes, fit: BoxFit.contain),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: isBusy ? null : onCatch,
                child: isBusy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Catch!'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: isBusy ? null : onRetake,
                child: const Text('Retake'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Catch result — shown after keepsake is created
// ---------------------------------------------------------------------------

class _CatchResult extends StatelessWidget {
  const _CatchResult({
    required this.keepsake,
    required this.isolatedBytes,
    required this.onScanAgain,
  });

  final Keepsake keepsake;
  final Uint8List? isolatedBytes;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _CheckerboardPainter(),
              child: Center(
                child: isolatedBytes != null
                    ? Image.memory(isolatedBytes!, fit: BoxFit.contain)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              children: [
                Text(
                  keepsake.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  keepsake.serialNumber,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/collection'),
                    child: const Text('Go to Collection'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onScanAgain,
                    child: const Text('Scan Again'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared painters + helpers
// ---------------------------------------------------------------------------

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tileSize = 16.0;
    final light = Paint()..color = const Color(0xFFEEEEEE);
    final dark = Paint()..color = const Color(0xFFCCCCCC);
    for (double y = 0; y < size.height; y += tileSize) {
      for (double x = 0; x < size.width; x += tileSize) {
        final isLight = ((x ~/ tileSize) + (y ~/ tileSize)) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, tileSize, tileSize),
          isLight ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) => false;
}

class _StillImage extends StatelessWidget {
  const _StillImage({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Image.memory(bytes, fit: BoxFit.cover);
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
