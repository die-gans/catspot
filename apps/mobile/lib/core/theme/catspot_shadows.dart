import 'package:flutter/material.dart';

import 'tokens.dart' as tokens;

/// All Catspot shadow tokens as a [ThemeExtension].
@immutable
class CatspotShadows extends ThemeExtension<CatspotShadows> {
  const CatspotShadows({
    required this.shadow0,
    required this.shadow1,
    required this.shadow2,
    required this.shadow3,
    required this.shadow4,
  });

  const CatspotShadows.light()
    : this(
        shadow0: tokens.shadow0,
        shadow1: tokens.shadow1,
        shadow2: tokens.shadow2,
        shadow3: tokens.shadow3,
        shadow4: tokens.shadow4,
      );

  final List<BoxShadow> shadow0;
  final List<BoxShadow> shadow1;
  final List<BoxShadow> shadow2;
  final List<BoxShadow> shadow3;
  final List<BoxShadow> shadow4;

  @override
  CatspotShadows copyWith({
    List<BoxShadow>? shadow0,
    List<BoxShadow>? shadow1,
    List<BoxShadow>? shadow2,
    List<BoxShadow>? shadow3,
    List<BoxShadow>? shadow4,
  }) {
    return CatspotShadows(
      shadow0: shadow0 ?? this.shadow0,
      shadow1: shadow1 ?? this.shadow1,
      shadow2: shadow2 ?? this.shadow2,
      shadow3: shadow3 ?? this.shadow3,
      shadow4: shadow4 ?? this.shadow4,
    );
  }

  @override
  CatspotShadows lerp(CatspotShadows? other, double t) {
    if (other == null) {
      return this;
    }
    return CatspotShadows(
      shadow0: _lerpShadows(shadow0, other.shadow0, t),
      shadow1: _lerpShadows(shadow1, other.shadow1, t),
      shadow2: _lerpShadows(shadow2, other.shadow2, t),
      shadow3: _lerpShadows(shadow3, other.shadow3, t),
      shadow4: _lerpShadows(shadow4, other.shadow4, t),
    );
  }

  static List<BoxShadow> _lerpShadows(
    List<BoxShadow> a,
    List<BoxShadow> b,
    double t,
  ) {
    final length = a.length;
    final result = List<BoxShadow>.generate(length, (index) {
      final otherShadow = b.length > index ? b[index] : a[index];
      return BoxShadow.lerp(a[index], otherShadow, t)!;
    });
    return result;
  }
}
