import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cat_detection_models.dart';
import 'cat_detection_service.dart';
import 'keepsake_model.dart';
import 'keepsake_service.dart';

@immutable
class ScanState {
  const ScanState({
    this.controller,
    this.isInitializing = true,
    this.error,
    this.detections = const [],
    this.isCaptureEnabled = false,
    this.isCapturing = false,
    this.capturedBytes,
    this.isIsolating = false,
    this.isolatedBytes,
    this.isCreatingKeepsake = false,
    this.keepsake,
  });

  final CameraController? controller;
  final bool isInitializing;
  final String? error;
  final List<CatDetection> detections;
  final bool isCaptureEnabled;

  /// Taking picture + running on-device detection.
  final bool isCapturing;

  /// Frozen JPEG shown in place of the live preview after shutter.
  final Uint8List? capturedBytes;

  /// Background removal is in flight.
  final bool isIsolating;

  /// Cat-only PNG with transparent background — the sticker.
  final Uint8List? isolatedBytes;

  /// R2 upload + Convex create + Photos save is in flight.
  final bool isCreatingKeepsake;

  /// Set once the keepsake is created; triggers the catch result screen.
  final Keepsake? keepsake;

  ScanState copyWith({
    CameraController? controller,
    bool? isInitializing,
    String? error,
    List<CatDetection>? detections,
    bool? isCaptureEnabled,
    bool? isCapturing,
    Uint8List? capturedBytes,
    bool? isIsolating,
    Uint8List? isolatedBytes,
    bool? isCreatingKeepsake,
    Keepsake? keepsake,
    bool clearError = false,
    bool clearCaptured = false,
    bool clearIsolated = false,
    bool clearKeepsake = false,
  }) {
    return ScanState(
      controller: controller ?? this.controller,
      isInitializing: isInitializing ?? this.isInitializing,
      error: clearError ? null : error ?? this.error,
      detections: detections ?? this.detections,
      isCaptureEnabled: isCaptureEnabled ?? this.isCaptureEnabled,
      isCapturing: isCapturing ?? this.isCapturing,
      capturedBytes: clearCaptured ? null : capturedBytes ?? this.capturedBytes,
      isIsolating: isIsolating ?? this.isIsolating,
      isolatedBytes: clearIsolated ? null : isolatedBytes ?? this.isolatedBytes,
      isCreatingKeepsake: isCreatingKeepsake ?? this.isCreatingKeepsake,
      keepsake: clearKeepsake ? null : keepsake ?? this.keepsake,
    );
  }
}

class ScanController extends StateNotifier<ScanState> {
  ScanController({
    required this.detectionService,
    required this.keepsakeService,
    this.previewResolution = ResolutionPreset.high,
  }) : super(const ScanState());

  final CatDetectionService detectionService;
  final KeepsakeService keepsakeService;
  final ResolutionPreset previewResolution;

  bool _isDisposed = false;
  CameraController? _cameraController;

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
        isCaptureEnabled: true,
        clearError: true,
      );
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

  /// Take a photo, freeze the preview, detect the cat, then auto-isolate.
  Future<void> capture() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    state = state.copyWith(isCapturing: true, isCaptureEnabled: false, clearError: true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();

      state = state.copyWith(capturedBytes: bytes);

      final detections = await detectionService.detect(bytes);
      if (_isDisposed) return;

      if (detections.isEmpty) {
        state = state.copyWith(
          isCapturing: false,
          detections: const [],
          error: 'No cat detected — retake',
        );
        return;
      }

      state = state.copyWith(
        isCapturing: false,
        detections: detections,
        isIsolating: true,
      );
    } on Exception catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(isCapturing: false, error: 'Capture failed: $e');
      return;
    }

    await _isolate();
  }

  Future<void> _isolate() async {
    final bytes = state.capturedBytes;
    if (bytes == null) return;

    try {
      final isolated = await detectionService.isolateSubject(bytes);
      if (_isDisposed) return;

      if (isolated == null) {
        state = state.copyWith(
          isIsolating: false,
          detections: const [],
          error: 'Could not isolate cat — retake',
        );
        return;
      }

      state = state.copyWith(
        isIsolating: false,
        isolatedBytes: isolated,
        detections: const [],
      );
    } on Exception catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(isIsolating: false, error: 'Isolation failed: $e');
    }
  }

  /// Upload the sticker to R2, create a keepsake, and save to Photos.
  Future<void> catchIt() async {
    final bytes = state.isolatedBytes;
    if (bytes == null) return;

    state = state.copyWith(isCreatingKeepsake: true, clearError: true);
    try {
      final keepsake = await keepsakeService.saveAndCreate(bytes);
      if (_isDisposed) return;
      state = state.copyWith(isCreatingKeepsake: false, keepsake: keepsake);
    } catch (e) {
      // Catch Object (not just Exception) — StateError from uninitialized
      // Convex client extends Error, not Exception.
      if (_isDisposed) return;
      state = state.copyWith(isCreatingKeepsake: false, error: 'Could not save: $e');
    }
  }

  /// Return to the live camera preview, clearing all captured/isolated state.
  void retake() {
    state = state.copyWith(
      clearCaptured: true,
      clearIsolated: true,
      clearKeepsake: true,
      clearError: true,
      detections: const [],
      isCaptureEnabled: true,
      isCapturing: false,
      isIsolating: false,
      isCreatingKeepsake: false,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }
}
