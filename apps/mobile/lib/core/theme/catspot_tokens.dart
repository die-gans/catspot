import 'package:flutter/material.dart';

import 'catspot_colors.dart';
import 'catspot_motion.dart';
import 'catspot_radius.dart';
import 'catspot_shadows.dart';
import 'catspot_spacing.dart';
import 'catspot_type.dart';

/// Convenience aggregate that exposes all Catspot [ThemeExtension]s.
@immutable
class CatspotTokens extends ThemeExtension<CatspotTokens> {
  // CatspotType is built from GoogleFonts and is not const-evaluable.
  // ignore: prefer_const_constructors_in_immutables
  CatspotTokens({
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.radius,
    required this.shadows,
    required this.motion,
  });

  CatspotTokens.light()
    : colors = const CatspotColors.light(),
      typography = CatspotType.light(),
      spacing = const CatspotSpacing.light(),
      radius = const CatspotRadius.light(),
      shadows = const CatspotShadows.light(),
      motion = const CatspotMotion.light();

  final CatspotColors colors;
  final CatspotType typography;
  final CatspotSpacing spacing;
  final CatspotRadius radius;
  final CatspotShadows shadows;
  final CatspotMotion motion;

  @override
  CatspotTokens copyWith({
    CatspotColors? colors,
    CatspotType? typography,
    CatspotSpacing? spacing,
    CatspotRadius? radius,
    CatspotShadows? shadows,
    CatspotMotion? motion,
  }) {
    return CatspotTokens(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      radius: radius ?? this.radius,
      shadows: shadows ?? this.shadows,
      motion: motion ?? this.motion,
    );
  }

  @override
  CatspotTokens lerp(CatspotTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return CatspotTokens(
      colors: colors.lerp(other.colors, t),
      typography: typography.lerp(other.typography, t),
      spacing: spacing.lerp(other.spacing, t),
      radius: radius.lerp(other.radius, t),
      shadows: shadows.lerp(other.shadows, t),
      motion: motion.lerp(other.motion, t),
    );
  }
}
