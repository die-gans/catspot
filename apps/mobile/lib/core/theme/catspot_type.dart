import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// All Catspot typography tokens as a [ThemeExtension].
@immutable
class CatspotType extends ThemeExtension<CatspotType> {
  // GoogleFonts text styles are not const-evaluable, so this constructor cannot
  // be const despite the immutable class.
  // ignore: prefer_const_constructors_in_immutables
  CatspotType({
    required this.displayLarge,
    required this.displayMedium,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.bodyStrong,
    required this.label,
    required this.caption,
    required this.mono,
  });

  CatspotType.light()
    : displayLarge = GoogleFonts.quicksand(
        textStyle: const TextStyle(
          fontSize: typeDisplayLargeSize,
          fontWeight: typeDisplayWeight,
          height: typeDisplayLargeLineHeight / typeDisplayLargeSize,
          letterSpacing: typeDisplayLargeLetterSpacing,
        ),
      ),
      displayMedium = GoogleFonts.quicksand(
        textStyle: const TextStyle(
          fontSize: typeDisplayMediumSize,
          fontWeight: typeDisplayWeight,
          height: typeDisplayMediumLineHeight / typeDisplayMediumSize,
          letterSpacing: typeDisplayMediumLetterSpacing,
        ),
      ),
      title = GoogleFonts.quicksand(
        textStyle: const TextStyle(
          fontSize: typeTitleSize,
          fontWeight: typeTitleWeight,
          height: typeTitleLineHeight / typeTitleSize,
          letterSpacing: typeTitleLetterSpacing,
        ),
      ),
      subtitle = GoogleFonts.quicksand(
        textStyle: const TextStyle(
          fontSize: typeSubtitleSize,
          fontWeight: typeSubtitleWeight,
          height: typeSubtitleLineHeight / typeSubtitleSize,
          letterSpacing: typeSubtitleLetterSpacing,
        ),
      ),
      body = GoogleFonts.inter(
        textStyle: const TextStyle(
          fontSize: typeBodySize,
          fontWeight: typeBodyWeight,
          height: typeBodyLineHeight / typeBodySize,
          letterSpacing: typeBodyLetterSpacing,
        ),
      ),
      bodyStrong = GoogleFonts.inter(
        textStyle: const TextStyle(
          fontSize: typeBodySize,
          fontWeight: typeBodyStrongWeight,
          height: typeBodyLineHeight / typeBodySize,
          letterSpacing: typeBodyLetterSpacing,
        ),
      ),
      label = GoogleFonts.inter(
        textStyle: const TextStyle(
          fontSize: typeLabelSize,
          fontWeight: typeLabelWeight,
          height: typeLabelLineHeight / typeLabelSize,
          letterSpacing: typeLabelLetterSpacing,
        ),
      ),
      caption = GoogleFonts.inter(
        textStyle: const TextStyle(
          fontSize: typeCaptionSize,
          fontWeight: typeCaptionWeight,
          height: typeCaptionLineHeight / typeCaptionSize,
          letterSpacing: typeCaptionLetterSpacing,
        ),
      ),
      mono = GoogleFonts.robotoMono(
        textStyle: const TextStyle(
          fontSize: typeMonoSize,
          fontWeight: typeMonoWeight,
          height: typeMonoLineHeight / typeMonoSize,
          letterSpacing: typeMonoLetterSpacing,
        ),
      );

  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle title;
  final TextStyle subtitle;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle mono;

  @override
  CatspotType copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? title,
    TextStyle? subtitle,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? mono,
  }) {
    return CatspotType(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      mono: mono ?? this.mono,
    );
  }

  @override
  CatspotType lerp(CatspotType? other, double t) {
    if (other == null) {
      return this;
    }
    return CatspotType(
      displayLarge: TextStyle.lerp(displayLarge, other.displayLarge, t)!,
      displayMedium: TextStyle.lerp(displayMedium, other.displayMedium, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      subtitle: TextStyle.lerp(subtitle, other.subtitle, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyStrong: TextStyle.lerp(bodyStrong, other.bodyStrong, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      mono: TextStyle.lerp(mono, other.mono, t)!,
    );
  }
}
