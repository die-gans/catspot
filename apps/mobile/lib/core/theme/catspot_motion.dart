import 'package:flutter/material.dart';

import 'tokens.dart';

/// All Catspot motion tokens as a [ThemeExtension].
@immutable
class CatspotMotion extends ThemeExtension<CatspotMotion> {
  const CatspotMotion({
    required this.flip,
    required this.snap,
    required this.fade,
    required this.slideUp,
    required this.slideDown,
    required this.bounce,
    required this.ease,
    required this.flipCurve,
    required this.snapCurve,
    required this.fadeCurve,
    required this.slideUpCurve,
    required this.slideDownCurve,
    required this.bounceCurve,
    required this.easeCurve,
  });

  const CatspotMotion.light()
    : this(
        flip: motionFlipDuration,
        snap: motionSnapDuration,
        fade: motionFadeDuration,
        slideUp: motionSlideUpDuration,
        slideDown: motionSlideDownDuration,
        bounce: motionBounceDuration,
        ease: motionEaseDuration,
        flipCurve: motionFlipCurve,
        snapCurve: motionSnapCurve,
        fadeCurve: motionFadeCurve,
        slideUpCurve: motionSlideUpCurve,
        slideDownCurve: motionSlideDownCurve,
        bounceCurve: motionBounceCurve,
        easeCurve: motionEaseCurve,
      );

  final Duration flip;
  final Duration snap;
  final Duration fade;
  final Duration slideUp;
  final Duration slideDown;
  final Duration bounce;
  final Duration ease;

  final Curve flipCurve;
  final Curve snapCurve;
  final Curve fadeCurve;
  final Curve slideUpCurve;
  final Curve slideDownCurve;
  final Curve bounceCurve;
  final Curve easeCurve;

  @override
  CatspotMotion copyWith({
    Duration? flip,
    Duration? snap,
    Duration? fade,
    Duration? slideUp,
    Duration? slideDown,
    Duration? bounce,
    Duration? ease,
    Curve? flipCurve,
    Curve? snapCurve,
    Curve? fadeCurve,
    Curve? slideUpCurve,
    Curve? slideDownCurve,
    Curve? bounceCurve,
    Curve? easeCurve,
  }) {
    return CatspotMotion(
      flip: flip ?? this.flip,
      snap: snap ?? this.snap,
      fade: fade ?? this.fade,
      slideUp: slideUp ?? this.slideUp,
      slideDown: slideDown ?? this.slideDown,
      bounce: bounce ?? this.bounce,
      ease: ease ?? this.ease,
      flipCurve: flipCurve ?? this.flipCurve,
      snapCurve: snapCurve ?? this.snapCurve,
      fadeCurve: fadeCurve ?? this.fadeCurve,
      slideUpCurve: slideUpCurve ?? this.slideUpCurve,
      slideDownCurve: slideDownCurve ?? this.slideDownCurve,
      bounceCurve: bounceCurve ?? this.bounceCurve,
      easeCurve: easeCurve ?? this.easeCurve,
    );
  }

  @override
  CatspotMotion lerp(CatspotMotion? other, double t) {
    if (other == null) {
      return this;
    }
    return CatspotMotion(
      flip: _lerpDuration(flip, other.flip, t),
      snap: _lerpDuration(snap, other.snap, t),
      fade: _lerpDuration(fade, other.fade, t),
      slideUp: _lerpDuration(slideUp, other.slideUp, t),
      slideDown: _lerpDuration(slideDown, other.slideDown, t),
      bounce: _lerpDuration(bounce, other.bounce, t),
      ease: _lerpDuration(ease, other.ease, t),
      flipCurve: _lerpCurve(flipCurve, other.flipCurve, t),
      snapCurve: _lerpCurve(snapCurve, other.snapCurve, t),
      fadeCurve: _lerpCurve(fadeCurve, other.fadeCurve, t),
      slideUpCurve: _lerpCurve(slideUpCurve, other.slideUpCurve, t),
      slideDownCurve: _lerpCurve(slideDownCurve, other.slideDownCurve, t),
      bounceCurve: _lerpCurve(bounceCurve, other.bounceCurve, t),
      easeCurve: _lerpCurve(easeCurve, other.easeCurve, t),
    );
  }

  static Duration _lerpDuration(Duration a, Duration b, double t) {
    return Duration(
      microseconds:
          (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
              .round(),
    );
  }

  static Curve _lerpCurve(Curve a, Curve b, double t) {
    return t < 0.5 ? a : b;
  }
}
