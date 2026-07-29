import 'dart:ui';

import 'package:flutter/material.dart';

import 'tokens.dart' as tokens;

/// All Catspot spacing tokens as a [ThemeExtension].
@immutable
class CatspotSpacing extends ThemeExtension<CatspotSpacing> {
  const CatspotSpacing({
    required this.space0,
    required this.space1,
    required this.space2,
    required this.space3,
    required this.space4,
    required this.space5,
    required this.space6,
    required this.space8,
    required this.space10,
    required this.space12,
    required this.space16,
  });

  const CatspotSpacing.light()
    : this(
        space0: tokens.space0,
        space1: tokens.space1,
        space2: tokens.space2,
        space3: tokens.space3,
        space4: tokens.space4,
        space5: tokens.space5,
        space6: tokens.space6,
        space8: tokens.space8,
        space10: tokens.space10,
        space12: tokens.space12,
        space16: tokens.space16,
      );

  final double space0;
  final double space1;
  final double space2;
  final double space3;
  final double space4;
  final double space5;
  final double space6;
  final double space8;
  final double space10;
  final double space12;
  final double space16;

  @override
  CatspotSpacing copyWith({
    double? space0,
    double? space1,
    double? space2,
    double? space3,
    double? space4,
    double? space5,
    double? space6,
    double? space8,
    double? space10,
    double? space12,
    double? space16,
  }) {
    return CatspotSpacing(
      space0: space0 ?? this.space0,
      space1: space1 ?? this.space1,
      space2: space2 ?? this.space2,
      space3: space3 ?? this.space3,
      space4: space4 ?? this.space4,
      space5: space5 ?? this.space5,
      space6: space6 ?? this.space6,
      space8: space8 ?? this.space8,
      space10: space10 ?? this.space10,
      space12: space12 ?? this.space12,
      space16: space16 ?? this.space16,
    );
  }

  @override
  CatspotSpacing lerp(CatspotSpacing? other, double t) {
    if (other == null) {
      return this;
    }
    return CatspotSpacing(
      space0: lerpDouble(space0, other.space0, t)!,
      space1: lerpDouble(space1, other.space1, t)!,
      space2: lerpDouble(space2, other.space2, t)!,
      space3: lerpDouble(space3, other.space3, t)!,
      space4: lerpDouble(space4, other.space4, t)!,
      space5: lerpDouble(space5, other.space5, t)!,
      space6: lerpDouble(space6, other.space6, t)!,
      space8: lerpDouble(space8, other.space8, t)!,
      space10: lerpDouble(space10, other.space10, t)!,
      space12: lerpDouble(space12, other.space12, t)!,
      space16: lerpDouble(space16, other.space16, t)!,
    );
  }
}
