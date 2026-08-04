import 'cat_detection_models.dart';

/// Pure-Dart logic that tracks whether a stable cat detection has been observed
/// across recent frames.
///
/// A capture is enabled when a `Cat` detection with confidence >= [threshold]
/// appears in at least [requiredConsecutiveFrames] consecutive frames. The
/// counter resets as soon as a frame fails the check.
class CatDetectionGate {
  /// Create a gate with the default contract.
  ///
  /// Defaults match the spike contract: confidence >= 0.5 in >= 2 consecutive
  /// frames. The planning doc mentions >= 3 frames; this implementation follows
  /// the v2 skinny task instructions.
  CatDetectionGate({
    this.threshold = 0.5,
    this.requiredConsecutiveFrames = 2,
    this.targetLabel = 'Cat',
  });

  /// Minimum confidence required for a detection to count.
  final double threshold;

  /// Number of consecutive qualifying frames required to enable capture.
  final int requiredConsecutiveFrames;

  /// Label that qualifies as the target animal.
  final String targetLabel;

  int _streak = 0;

  /// Whether capture should currently be enabled.
  bool get isCaptureEnabled =>
      _streak >= requiredConsecutiveFrames;

  /// Number of consecutive qualifying frames seen so far.
  int get streak => _streak;

  /// Feed a new frame's detections into the gate.
  ///
  /// Returns `true` if the frame qualifies (contains at least one target
  /// detection above [threshold]).
  bool onFrame(List<CatDetection> detections) {
    final qualifies = detections.any(
      (d) => d.label == targetLabel && d.confidence >= threshold,
    );

    if (qualifies) {
      _streak++;
    } else {
      _streak = 0;
    }

    return qualifies;
  }

  /// Reset the streak, e.g. after a capture or when the user navigates away.
  void reset() {
    _streak = 0;
  }
}
