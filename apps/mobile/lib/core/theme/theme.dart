import 'package:flutter/material.dart';

import 'catspot_colors.dart';
import 'catspot_motion.dart';
import 'catspot_radius.dart';
import 'catspot_shadows.dart';
import 'catspot_spacing.dart';
import 'catspot_tokens.dart';
import 'catspot_type.dart';
import 'tokens.dart';

export 'catspot_colors.dart';
export 'catspot_motion.dart';
export 'catspot_radius.dart';
export 'catspot_shadows.dart';
export 'catspot_spacing.dart';
export 'catspot_theme.dart';
export 'catspot_tokens.dart';
export 'catspot_type.dart';
export 'tokens.dart';

/// Light Catspot [ThemeData].
///
/// A matching dark variant can be added later by creating a
/// [catspotDarkThemeData] function that returns the same extension classes with
/// dark surface/ink values; the token names themselves do not need to change.
ThemeData catspotLightThemeData() {
  const colors = CatspotColors.light();
  final type = CatspotType.light();
  const spacing = CatspotSpacing.light();
  const radius = CatspotRadius.light();
  const shadows = CatspotShadows.light();
  const motion = CatspotMotion.light();
  final tokens = CatspotTokens.light();

  final colorScheme = _buildColorScheme(colors);
  final textTheme = _buildTextTheme(type);
  final elevatedButtonTheme = _buildPrimaryButtonTheme(colors, type, radius);
  final outlinedButtonTheme = _buildGhostButtonTheme(colors, type, radius);
  final textButtonTheme = _buildDestructiveButtonTheme(colors, type, radius);
  final chipTheme = _buildChipTheme(colors, type, radius);
  final bottomSheetTheme = _buildBottomSheetTheme(colors, radius);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: colors.surfaceBase,
    elevatedButtonTheme: elevatedButtonTheme,
    outlinedButtonTheme: outlinedButtonTheme,
    textButtonTheme: textButtonTheme,
    chipTheme: chipTheme,
    bottomSheetTheme: bottomSheetTheme,
    extensions: <ThemeExtension<dynamic>>[
      colors,
      type,
      spacing,
      radius,
      shadows,
      motion,
      tokens,
    ],
  );
}

ColorScheme _buildColorScheme(CatspotColors colors) {
  return ColorScheme(
    brightness: Brightness.light,
    primary: colors.brandPrimary,
    onPrimary: colors.inkInverse,
    secondary: colors.brandSecondary,
    onSecondary: colors.inkPrimary,
    tertiary: colors.semanticInfo,
    onTertiary: colors.inkInverse,
    error: colors.semanticError,
    onError: colors.inkInverse,
    surface: colors.surfaceBase,
    onSurface: colors.inkPrimary,
    surfaceContainer: colors.surfacePaper,
    surfaceContainerHighest: colors.surfaceCard,
    outline: colors.border,
    outlineVariant: colors.divider,
    shadow: colors.surfaceOverlay,
    inverseSurface: colors.inkPrimary,
    onInverseSurface: colors.inkInverse,
    inversePrimary: colors.brandSecondary,
  );
}

TextTheme _buildTextTheme(CatspotType type) {
  return TextTheme(
    displayLarge: type.displayLarge,
    displayMedium: type.displayMedium,
    titleLarge: type.title,
    titleMedium: type.subtitle,
    bodyLarge: type.body,
    bodyMedium: type.bodyStrong,
    labelLarge: type.label,
    bodySmall: type.caption,
    labelMedium: type.mono,
  );
}

ElevatedButtonThemeData _buildPrimaryButtonTheme(
  CatspotColors colors,
  CatspotType type,
  CatspotRadius radius,
) {
  return ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(colors.brandPrimary),
      foregroundColor: WidgetStatePropertyAll(colors.inkInverse),
      textStyle: WidgetStatePropertyAll(type.label),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: space4, vertical: space3),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.radiusSm),
        ),
      ),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return 2;
        if (states.contains(WidgetState.hovered)) return 2;
        return 1;
      }),
      shadowColor: WidgetStatePropertyAll(colors.surfaceOverlay),
      minimumSize: const WidgetStatePropertyAll(Size(88, 44)),
    ),
  );
}

OutlinedButtonThemeData _buildGhostButtonTheme(
  CatspotColors colors,
  CatspotType type,
  CatspotRadius radius,
) {
  return OutlinedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colors.brandPrimarySurface;
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return colors.inkTertiary;
        return colors.brandPrimary;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: colors.inkTertiary);
        }
        return BorderSide(color: colors.brandPrimary);
      }),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      textStyle: WidgetStatePropertyAll(type.label),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: space4, vertical: space3),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.radiusSm),
        ),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(88, 44)),
    ),
  );
}

TextButtonThemeData _buildDestructiveButtonTheme(
  CatspotColors colors,
  CatspotType type,
  CatspotRadius radius,
) {
  return TextButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(colors.semanticError),
      foregroundColor: WidgetStatePropertyAll(colors.inkInverse),
      textStyle: WidgetStatePropertyAll(type.label),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: space4, vertical: space3),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.radiusSm),
        ),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(88, 44)),
    ),
  );
}

ChipThemeData _buildChipTheme(
  CatspotColors colors,
  CatspotType type,
  CatspotRadius radius,
) {
  return ChipThemeData(
    color: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colors.brandPrimarySurface;
      }
      return colors.surfaceCard;
    }),
    side: BorderSide(color: colors.border),
    labelStyle: type.label,
    padding: const EdgeInsets.symmetric(horizontal: space3, vertical: space2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius.radiusSm),
    ),
    showCheckmark: false,
    checkmarkColor: colors.brandPrimary,
    iconTheme: IconThemeData(color: colors.inkSecondary, size: 16),
    labelPadding: EdgeInsets.zero,
  );
}

BottomSheetThemeData _buildBottomSheetTheme(
  CatspotColors colors,
  CatspotRadius radius,
) {
  return BottomSheetThemeData(
    backgroundColor: colors.surfaceCard,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(radius.radiusLg),
        topRight: Radius.circular(radius.radiusLg),
      ),
    ),
    showDragHandle: true,
    dragHandleColor: colors.inkTertiary,
    dragHandleSize: const Size(36, 4),
    modalBackgroundColor: colors.surfaceOverlay,
    clipBehavior: Clip.antiAlias,
  );
}
