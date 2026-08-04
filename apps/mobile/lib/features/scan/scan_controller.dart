import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cat_detection_gate.dart';
import 'cat_detection_models.dart';
import 'cat_detection_service.dart';
import 'scan_verifier.dart';

/// Mutable state of the scan debug screen.
@immutable
class ScanState {
  /// Create a scan state.
  const ScanState({
    this.controller,
    this.isInitializing = true,
    this.error,
    this.detections = const [],
    this.isCaptureEnabled = false,
    this.isCapturing = false,
    this.lastResult,
  });

  /// Active camera controller, once initialized.
  final CameraController? controller;

  /// Whether the camera is still initializing.
  final bool isInitializing;

  /// Fatal or non-fatal error to display.
  final String? error;

  /// Detections from the most recent frame.
  final List<CatDetection> detections;

  /// Whether the shutter button is enabled (stable cat detection).
  final bool isCaptureEnabled;

  /// Whether a full-res capture + verify is in flight.
  final bool isCapturing;

  /// Most recent backend result message, if any.
  final ScanResult? lastResult;

  /// Copy the state with the given fields replaced.
  ScanState copyWith({
    CameraController? controller,
    bool? isInitializing,
    String? error,
    List<CatDetection>? detections,
    bool? isCaptureEnabled,
    bool? isCapturing,
    ScanResult? lastResult,
    bool clearError = false,
  }) {
    return ScanState(
      controller: controller ?? this.controller,
      isInitializing: isInitializing ?? this.isInitializing,
      error: clearError ? null : error ?? this.error,
      detections: detections ?? this.detections,
      isCaptureEnabled: isCaptureEnabled ?? this.isCaptureEnabled,
      isCapturing: isCapturing ?? this.isCapturing,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

/// State controller for the scan debug screen.
///
/// Manages camera initialization, a periodic low-res frame loop, on-device cat
/// detection, and the full-res capture + verify flow.
class ScanController extends StateNotifier<ScanState> {
  /// Create the controller.
  ScanController({
    required this.detectionService,
    required this.verifier,
    this.frameInterval = const Duration(milliseconds: 500),
    this.previewResolution = ResolutionPreset.low,
  }) : super(const ScanState());

  /// Service used for on-device animal detection.
  final CatDetectionService detectionService;

  /// Backend verifier for the capture flow.
  final ScanVerifier verifier;

  /// Delay between low-res detection frames.
  final Duration frameInterval;

  /// Camera preview resolution preset.
  final ResolutionPreset previewResolution;

  final CatDetectionGate _gate = CatDetectionGate();
  Timer? _frameTimer;
  bool _isDisposed = false;
  CameraController? _cameraController;

  /// Initialize the camera and start the detection loop.
  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(
          isInitializing: false,
          error: 'No camera available',
        );
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController?.dispose();
      _cameraController = CameraController(
        backCamera,
        previewResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (_isDisposed) {
        _cameraController?.dispose();
        return;
      }

      state = state.copyWith(
        controller: _cameraController,
        isInitializing: false,
        clearError: true,
      );

      _startFrameLoop();
    } on CameraException catch (e) {
      state = state.copyWith(
        isInitializing: false,
        error: 'Camera error: ${e.description}',
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isInitializing: false,
        error: 'Could not start camera: $e',
      );
    }
  }

  void _startFrameLoop() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(frameInterval, (_) => _processFrame());
  }

  Future<void> _processFrame() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final detections = await detectionService.detect(bytes);

      if (_isDisposed) return;

      _gate.onFrame(detections);

      state = state.copyWith(
        detections: detections,
        isCaptureEnabled: _gate.isCaptureEnabled,
        clearError: true,
      );
    } on Exception catch (e) {
      // Frame-loop errors are non-fatal; keep the preview alive and surface the
      // message so it is not swallowed.
      state = state.copyWith(error: 'Frame loop: $e');
    }
  }

  /// Capture a full-resolution photo and run the verify flow.
  Future<void> capture() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    state = state.copyWith(isCapturing: true, clearError: true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final result = await verifier.captureAndVerify(bytes);

      if (_isDisposed) return;

      _gate.reset();
      state = state.copyWith(
        isCapturing: false,
        lastResult: result,
        isCaptureEnabled: false,
      );
    } on Exception catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(
        isCapturing: false,
        error: 'Capture failed: $e',
      );
    }
  }

  /// Clear the most recent backend result.
  void clearResult() {
    state = state.copyWith(lastResult: null);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _frameTimer?.cancel();
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }
}
