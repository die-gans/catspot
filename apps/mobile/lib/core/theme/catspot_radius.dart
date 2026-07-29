import 'dart:ui';

import 'package:flutter/material.dart';

import 'tokens.dart' as tokens;

/// All Catspot radius tokens as a [ThemeExtension].
@immutable
class CatspotRadius extends ThemeExtension<CatspotRadius> {
  const CatspotRadius({
    required this.radiusNone,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusFull,
  });

  const CatspotRadius.light()
    : this(
        radiusNone: tokens.radiusNone,
        radiusSm: tokens.radiusSm,
        radiusMd: tokens.radiusMd,
        radiusLg: tokens.radiusLg,
        radiusXl: tokens.radiusXl,
        radiusFull: tokens.radiusFull,
      );

  final double radiusNone;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double radiusFull;

  @override
  CatspotRadius copyWith({
    double? radiusNone,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? radiusFull,
  }) {
    return CatspotRadius(
      radiusNone: radiusNone ?? this.radiusNone,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      radiusFull: radiusFull ?? this.radiusFull,
    );
  }

  @override
  CatspotRadius lerp(CatspotRadius? other, double t) {
    if (other == null) {
      return this;
    }
    return CatspotRadius(
      radiusNone: lerpDouble(radiusNone, other.radiusNone, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusXl: lerpDouble(radiusXl, other.radiusXl, t)!,
      radiusFull: lerpDouble(radiusFull, other.radiusFull, t)!,
    );
  }
}
