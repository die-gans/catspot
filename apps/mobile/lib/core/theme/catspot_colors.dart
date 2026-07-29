import 'package:flutter/material.dart';

import 'tokens.dart';

/// All Catspot color tokens as a [ThemeExtension].
@immutable
class CatspotColors extends ThemeExtension<CatspotColors> {
  const CatspotColors({
    required this.brandPrimary,
    required this.brandPrimaryHover,
    required this.brandPrimaryPressed,
    required this.brandSecondary,
    required this.brandPrimarySurface,
    required this.surfaceBase,
    required this.surfacePaper,
    required this.surfaceCard,
    required this.surfaceOverlay,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.inkInverse,
    required this.divider,
    required this.border,
    required this.rarityCommon,
    required this.rarityUncommon,
    required this.rarityRare,
    required this.rarityEpic,
    required this.rarityLegendary,
    required this.rarityCommonLight,
    required this.rarityUncommonLight,
    required this.rarityRareLight,
    required this.rarityEpicLight,
    required this.rarityLegendaryLight,
    required this.semanticSuccess,
    required this.semanticWarning,
    required this.semanticError,
    required this.semanticInfo,
  });

  const CatspotColors.light()
    : this(
        brandPrimary: colorBrandPrimary,
        brandPrimaryHover: colorBrandPrimaryHover,
        brandPrimaryPressed: colorBrandPrimaryPressed,
        brandSecondary: colorBrandSecondary,
        brandPrimarySurface: colorBrandPrimarySurface,
        surfaceBase: colorSurfaceBase,
        surfacePaper: colorSurfacePaper,
        surfaceCard: colorSurfaceCard,
        surfaceOverlay: colorSurfaceOverlay,
        inkPrimary: colorInkPrimary,
        inkSecondary: colorInkSecondary,
        inkTertiary: colorInkTertiary,
        inkInverse: colorInkInverse,
        divider: colorDivider,
        border: colorBorder,
        rarityCommon: colorRarityCommon,
        rarityUncommon: colorRarityUncommon,
        rarityRare: colorRarityRare,
        rarityEpic: colorRarityEpic,
        rarityLegendary: colorRarityLegendary,
        rarityCommonLight: colorRarityCommonLight,
        rarityUncommonLight: colorRarityUncommonLight,
        rarityRareLight: colorRarityRareLight,
        rarityEpicLight: colorRarityEpicLight,
        rarityLegendaryLight: colorRarityLegendaryLight,
        semanticSuccess: colorSemanticSuccess,
        semanticWarning: colorSemanticWarning,
        semanticError: colorSemanticError,
        semanticInfo: colorSemanticInfo,
      );

  final Color brandPrimary;
  final Color brandPrimaryHover;
  final Color brandPrimaryPressed;
  final Color brandSecondary;
  final Color brandPrimarySurface;
  final Color surfaceBase;
  final Color surfacePaper;
  final Color surfaceCard;
  final Color surfaceOverlay;
  final Color inkPrimary;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color inkInverse;
  final Color divider;
  final Color border;
  final Color rarityCommon;
  final Color rarityUncommon;
  final Color rarityRare;
  final Color rarityEpic;
  final Color rarityLegendary;
  final Color rarityCommonLight;
  final Color rarityUncommonLight;
  final Color rarityRareLight;
  final Color rarityEpicLight;
  final Color rarityLegendaryLight;
  final Color semanticSuccess;
  final Color semanticWarning;
  final Color semanticError;
  final Color semanticInfo;

  @override
  CatspotColors copyWith({
    Color? brandPrimary,
    Color? brandPrimaryHover,
    Color? brandPrimaryPressed,
    Color? brandSecondary,
    Color? brandPrimarySurface,
    Color? surfaceBase,
    Color? surfacePaper,
    Color? surfaceCard,
    Color? surfaceOverlay,
    Color? inkPrimary,
    Color? inkSecondary,
    Color? inkTertiary,
    Color? inkInverse,
    Color? divider,
    Color? border,
    Color? rarityCommon,
    Color? rarityUncommon,
    Color? rarityRare,
    Color? rarityEpic,
    Color? rarityLegendary,
    Color? rarityCommonLight,
    Color? rarityUncommonLight,
    Color? rarityRareLight,
    Color? rarityEpicLight,
    Color? rarityLegendaryLight,
    Color? semanticSuccess,
    Color? semanticWarning,
    Color? semanticError,
    Color? semanticInfo,
  }) {
    return CatspotColors(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandPrimaryHover: brandPrimaryHover ?? this.brandPrimaryHover,
      brandPrimaryPressed: brandPrimaryPressed ?? this.brandPrimaryPressed,
      brandSecondary: brandSecondary ?? this.brandSecondary,
      brandPrimarySurface: brandPrimarySurface ?? this.brandPrimarySurface,
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfacePaper: surfacePaper ?? this.surfacePaper,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      inkPrimary: inkPrimary ?? this.inkPrimary,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkTertiary: inkTertiary ?? this.inkTertiary,
      inkInverse: inkInverse ?? this.inkInverse,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      rarityCommon: rarityCommon ?? this.rarityCommon,
      rarityUncommon: rarityUncommon ?? this.rarityUncommon,
      rarityRare: rarityRare ?? this.rarityRare,
      rarityEpic: rarityEpic ?? this.rarityEpic,
      rarityLegendary: rarityLegendary ?? this.rarityLegendary,
      rarityCommonLight: rarityCommonLight ?? this.rarityCommonLight,
      rarityUncommonLight: rarityUncommonLight ?? this.rarityUncommonLight,
      rarityRareLight: rarityRareLight ?? this.rarityRareLight,
      rarityEpicLight: rarityEpicLight ?? this.rarityEpicLight,
      rarityLegendaryLight: rarityLegendaryLight ?? this.rarityLegendaryLight,
      semanticSuccess: semanticSuccess ?? this.semanticSuccess,
      semanticWarning: semanticWarning ?? this.semanticWarning,
      semanticError: semanticError ?? this.semanticError,
      semanticInfo: semanticInfo ?? this.semanticInfo,
    );
  }

  @override
  CatspotColors lerp(CatspotColors? other, double t) {
    if (other == null) {
      return this;
    }
    return CatspotColors(
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandPrimaryHover: Color.lerp(
        brandPrimaryHover,
        other.brandPrimaryHover,
        t,
      )!,
      brandPrimaryPressed: Color.lerp(
        brandPrimaryPressed,
        other.brandPrimaryPressed,
        t,
      )!,
      brandSecondary: Color.lerp(brandSecondary, other.brandSecondary, t)!,
      brandPrimarySurface: Color.lerp(
        brandPrimarySurface,
        other.brandPrimarySurface,
        t,
      )!,
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      surfacePaper: Color.lerp(surfacePaper, other.surfacePaper, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      inkPrimary: Color.lerp(inkPrimary, other.inkPrimary, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      inkTertiary: Color.lerp(inkTertiary, other.inkTertiary, t)!,
      inkInverse: Color.lerp(inkInverse, other.inkInverse, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      rarityCommon: Color.lerp(rarityCommon, other.rarityCommon, t)!,
      rarityUncommon: Color.lerp(rarityUncommon, other.rarityUncommon, t)!,
      rarityRare: Color.lerp(rarityRare, other.rarityRare, t)!,
      rarityEpic: Color.lerp(rarityEpic, other.rarityEpic, t)!,
      rarityLegendary: Color.lerp(rarityLegendary, other.rarityLegendary, t)!,
      rarityCommonLight: Color.lerp(
        rarityCommonLight,
        other.rarityCommonLight,
        t,
      )!,
      rarityUncommonLight: Color.lerp(
        rarityUncommonLight,
        other.rarityUncommonLight,
        t,
      )!,
      rarityRareLight: Color.lerp(rarityRareLight, other.rarityRareLight, t)!,
      rarityEpicLight: Color.lerp(rarityEpicLight, other.rarityEpicLight, t)!,
      rarityLegendaryLight: Color.lerp(
        rarityLegendaryLight,
        other.rarityLegendaryLight,
        t,
      )!,
      semanticSuccess: Color.lerp(semanticSuccess, other.semanticSuccess, t)!,
      semanticWarning: Color.lerp(semanticWarning, other.semanticWarning, t)!,
      semanticError: Color.lerp(semanticError, other.semanticError, t)!,
      semanticInfo: Color.lerp(semanticInfo, other.semanticInfo, t)!,
    );
  }
}
