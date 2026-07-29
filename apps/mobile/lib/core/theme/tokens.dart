import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Brand
// ---------------------------------------------------------------------------
const Color colorBrandPrimary = Color(0xFFE86A33);
const Color colorBrandPrimaryHover = Color(0xFFD45A26);
const Color colorBrandPrimaryPressed = Color(0xFFB94A1B);
const Color colorBrandSecondary = Color(0xFFF7B267);
const Color colorBrandPrimarySurface = Color(0xFFFFF0E8);

// ---------------------------------------------------------------------------
// Surfaces & ink
// ---------------------------------------------------------------------------
const Color colorSurfaceBase = Color(0xFFFDF8F0);
const Color colorSurfacePaper = Color(0xFFFFFDF9);
const Color colorSurfaceCard = Color(0xFFFFFFFF);
const Color colorSurfaceOverlay = Color.fromRGBO(44, 36, 25, 0.48);

const Color colorInkPrimary = Color(0xFF2C2419);
const Color colorInkSecondary = Color(0xFF6B5E4F);
const Color colorInkTertiary = Color(0xFF75695A);
const Color colorInkInverse = Color(0xFFFFFFFF);

const Color colorDivider = Color(0xFFE8E0D5);
const Color colorBorder = Color(0xFFD9CFC0);

// ---------------------------------------------------------------------------
// Rarity
// ---------------------------------------------------------------------------
const Color colorRarityCommon = Color(0xFF666666);
const Color colorRarityUncommon = Color(0xFF216944);
const Color colorRarityRare = Color(0xFF2060B0);
const Color colorRarityEpic = Color(0xFF7A3FBF);
const Color colorRarityLegendary = Color(0xFF8A6A00);

const Color colorRarityCommonLight = Color(0xFFD9CFC0);
const Color colorRarityUncommonLight = Color(0xFF3D9A69);
const Color colorRarityRareLight = Color(0xFF4A90E2);
const Color colorRarityEpicLight = Color(0xFFA66BE0);
const Color colorRarityLegendaryLight = Color(0xFFE8C44D);

// ---------------------------------------------------------------------------
// Semantic
// ---------------------------------------------------------------------------
const Color colorSemanticSuccess = Color(0xFF2E8B57);
const Color colorSemanticWarning = Color(0xFF9A6000);
const Color colorSemanticError = Color(0xFFC93E3E);
const Color colorSemanticInfo = Color(0xFF2060B0);

// ---------------------------------------------------------------------------
// Type scale
// ---------------------------------------------------------------------------
const double typeDisplayLargeSize = 32;
const double typeDisplayMediumSize = 28;
const double typeTitleSize = 24;
const double typeSubtitleSize = 20;
const double typeBodySize = 16;
const double typeLabelSize = 14;
const double typeCaptionSize = 12;
const double typeMonoSize = 14;

const FontWeight typeDisplayWeight = FontWeight.w700;
const FontWeight typeTitleWeight = FontWeight.w700;
const FontWeight typeSubtitleWeight = FontWeight.w600;
const FontWeight typeBodyWeight = FontWeight.w400;
const FontWeight typeBodyStrongWeight = FontWeight.w600;
const FontWeight typeLabelWeight = FontWeight.w600;
const FontWeight typeCaptionWeight = FontWeight.w400;
const FontWeight typeMonoWeight = FontWeight.w500;

const double typeDisplayLargeLineHeight = 40;
const double typeDisplayMediumLineHeight = 36;
const double typeTitleLineHeight = 32;
const double typeSubtitleLineHeight = 28;
const double typeBodyLineHeight = 24;
const double typeLabelLineHeight = 20;
const double typeCaptionLineHeight = 16;
const double typeMonoLineHeight = 20;

const double typeDisplayLargeLetterSpacing = -0.5;
const double typeDisplayMediumLetterSpacing = -0.5;
const double typeTitleLetterSpacing = -0.3;
const double typeSubtitleLetterSpacing = -0.2;
const double typeBodyLetterSpacing = 0;
const double typeLabelLetterSpacing = 0;
const double typeCaptionLetterSpacing = 0.2;
const double typeMonoLetterSpacing = 0;

// ---------------------------------------------------------------------------
// Spacing (4pt grid)
// ---------------------------------------------------------------------------
const double space0 = 0;
const double space1 = 4;
const double space2 = 8;
const double space3 = 12;
const double space4 = 16;
const double space5 = 20;
const double space6 = 24;
const double space8 = 32;
const double space10 = 40;
const double space12 = 48;
const double space16 = 64;

// ---------------------------------------------------------------------------
// Radius
// ---------------------------------------------------------------------------
const double radiusNone = 0;
const double radiusSm = 8;
const double radiusMd = 12;
const double radiusLg = 16;
const double radiusXl = 20;
const double radiusFull = 9999;

// ---------------------------------------------------------------------------
// Shadows
// ---------------------------------------------------------------------------
const List<BoxShadow> shadow0 = <BoxShadow>[];
const List<BoxShadow> shadow1 = <BoxShadow>[
  BoxShadow(
    color: Color.fromRGBO(44, 36, 25, 0.08),
    offset: Offset(0, 1),
    blurRadius: 3,
  ),
  BoxShadow(
    color: Color.fromRGBO(44, 36, 25, 0.04),
    offset: Offset(0, 1),
    blurRadius: 2,
  ),
];
const List<BoxShadow> shadow2 = <BoxShadow>[
  BoxShadow(
    color: Color.fromRGBO(44, 36, 25, 0.10),
    offset: Offset(0, 4),
    blurRadius: 12,
  ),
  BoxShadow(
    color: Color.fromRGBO(44, 36, 25, 0.06),
    offset: Offset(0, 2),
    blurRadius: 4,
  ),
];
const List<BoxShadow> shadow3 = <BoxShadow>[
  BoxShadow(
    color: Color.fromRGBO(44, 36, 25, 0.12),
    offset: Offset(0, 12),
    blurRadius: 24,
  ),
  BoxShadow(
    color: Color.fromRGBO(44, 36, 25, 0.08),
    offset: Offset(0, 4),
    blurRadius: 8,
  ),
];
const List<BoxShadow> shadow4 = <BoxShadow>[
  BoxShadow(
    color: Color.fromRGBO(44, 36, 25, 0.16),
    offset: Offset(0, 24),
    blurRadius: 48,
  ),
  BoxShadow(
    color: Color.fromRGBO(44, 36, 25, 0.10),
    offset: Offset(0, 8),
    blurRadius: 16,
  ),
];

// ---------------------------------------------------------------------------
// Motion
// ---------------------------------------------------------------------------
const Duration motionFlipDuration = Duration(milliseconds: 400);
const Duration motionSnapDuration = Duration(milliseconds: 100);
const Duration motionFadeDuration = Duration(milliseconds: 150);
const Duration motionSlideUpDuration = Duration(milliseconds: 200);
const Duration motionSlideDownDuration = Duration(milliseconds: 150);
const Duration motionBounceDuration = Duration(milliseconds: 200);
const Duration motionEaseDuration = Duration(milliseconds: 200);

const Curve motionFlipCurve = Curves.easeInOut;
const Curve motionSnapCurve = Curves.easeOut;
const Curve motionFadeCurve = Curves.easeInOut;
const Curve motionSlideUpCurve = Curves.easeOut;
const Curve motionSlideDownCurve = Curves.easeIn;
const Curve motionBounceCurve = Curves.easeOutBack;
const Curve motionEaseCurve = Curves.easeInOut;
