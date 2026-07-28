import 'package:flutter/material.dart';

typedef LivestTypography = BrawigoTypography;

class BrawigoTypography {
  BrawigoTypography._();

  static const String _font = 'PlusJakartaSans';

  // ───────────────── DISPLAY ─────────────────
  static const TextStyle displayLg = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMd = TextStyle(
    fontFamily: _font,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle displaySm = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  // ───────────────── HEADING ─────────────────
  static const TextStyle h1 = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle h5 = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle h6 = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  // ───────────────── BODY LG ─────────────────
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodyLgMedium = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );

  static const TextStyle bodyLgSemiBold = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.6,
  );

  static const TextStyle bodyLgBold = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.6,
  );

  // ───────────────── BODY MD ─────────────────
  static const TextStyle bodyMd = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodyMdMedium = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );

  static const TextStyle bodyMdSemiBold = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.6,
  );

  static const TextStyle bodyMdBold = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.6,
  );

  // ───────────────── BODY SM ─────────────────
  static const TextStyle bodySm = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodySmMedium = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodySmSemiBold = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodySmBold = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  // ───────────────── TEXT ─────────────────
  static const TextStyle textLg = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle textMd = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle textSm = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // ───────────────── CAPTION ─────────────────
  static const TextStyle captionSmSemibold = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    // letterSpacing: 0.2,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );

  static const TextStyle captionMedium = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle captionBold = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  // ───────────────── BUTTON ─────────────────
  static const TextStyle buttonLg = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle buttonMd = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle buttonSm = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  // ───────────────── TEXT THEME ─────────────────
  static TextTheme get textTheme => const TextTheme(
    displayLarge: displayLg,
    displayMedium: displayMd,
    displaySmall: displaySm,

    headlineLarge: h1,
    headlineMedium: h2,
    headlineSmall: h3,

    titleLarge: h4,
    titleMedium: h5,
    titleSmall: h6,

    bodyLarge: bodyLg,
    bodyMedium: bodyMd,
    bodySmall: bodySm,

    labelLarge: buttonMd,
    labelMedium: textSm,
    labelSmall: caption,
  );
}
