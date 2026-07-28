import 'package:flutter/material.dart';

class BrawigoColors {
  // --- Primary Colors (Scale 50 - 950) ---
  static const Color primary50 = Color(0xfff3f7fc);
  static const Color primary100 = Color(0xffe6edf8);
  static const Color primary200 = Color(0xffc8daef);
  static const Color primary300 = Color(0xff97bae2);
  static const Color primary400 = Color(0xff6097d0);
  static const Color primary500 = Color(0xff3873b2);
  static const Color primary = primary500;
  static const Color primary600 = Color(0xff2b5f9e);
  static const Color primary700 = Color(0xff244c80);
  static const Color primary800 = Color(0xff21426b);
  static const Color primary900 = Color(0xff20395a);
  static const Color primary950 = Color(0xff15243c);

  // --- Blue / Primary State Colors ---
  static const Color blueLight = Color(0xffe8f3ff);
  static const Color blueLightHover = Color(0xffd9edff);
  static const Color blueLightActive = Color(0xffb2daff);
  static const Color blueNormal = Color(0xff0088ff);
  static const Color blueNormalHover = Color(0xff007ae6);
  static const Color blueNormalActive = Color(0xff006dcc);
  static const Color blueDark = Color(0xff0066bf);
  static const Color blueDarkHover = Color(0xff005299);
  static const Color blueDarkActive = Color(0xff003d73);
  static const Color blueDarker = Color(0xff003059);

  // Legacy Primary aliases mapped to Blue state colors
  static const Color primaryLight = blueLight;
  static const Color primaryLightHover = blueLightHover;
  static const Color primaryLightActive = blueLightActive;
  static const Color primaryNormal = blueNormal;
  static const Color primaryNormalHover = blueNormalHover;
  static const Color primaryNormalActive = blueNormalActive;
  static const Color primaryDark = blueDark;
  static const Color primaryDarkHover = blueDarkHover;
  static const Color primaryDarkActive = blueDarkActive;
  static const Color primaryDarker = blueDarker;

  // --- Base Colors ---
  static const Color baseWhite = Colors.white;
  static const Color baseBlack = Colors.black;
  static const Color baseBackground = Color(0xfffdfdfd);

  // --- Text Colors ---
  static const Color textHeading = Color(0xff15243c); // Aligned with primary950
  static const Color textPrimary = Color(0xff1A1A1A);
  static const Color textSecondary = Color(0xff515151);
  static const Color textWhite = Colors.white;

  // --- Neutral ---
  static const Color neutralLight = Color(0xfffdfdfd);
  static const Color neutralLightHover = Color(0xfffbfbfb);
  static const Color neutralLightActive = Color(0xfff7f7f7);
  static const Color neutralNormal = Color(0xffe6e6e6);
  static const Color neutralNormalHover = Color(0xffcfcfcf);
  static const Color neutralNormalActive = Color(0xffb8b8b8);
  static const Color neutralDark = Color(0xffadadad);
  static const Color neutralDarkHover = Color(0xff8a8a8a);
  static const Color neutralDarkActive = Color(0xff676767);
  static const Color neutralDarker = Color(0xff515151);

  // --- Green ---
  static const Color greenLight = Color(0xffe8f7eb);
  static const Color greenLightHover = Color(0xffddf3e2);
  static const Color greenLightActive = Color(0xffb9e6c3);
  static const Color greenNormal = Color(0xff1cae50);
  static const Color greenNormalHover = Color(0xff199d48);
  static const Color greenNormalActive = Color(0xff168b40);
  static const Color greenDark = Color(0xff15833c);
  static const Color greenDarkHover = Color(0xff116830);
  static const Color greenDarkActive = Color(0xff0d4e24);
  static const Color greenDarker = Color(0xff0a3d1c);

  // --- Yellow ---
  static const Color yellowLight = Color(0xfffef8e4);
  static const Color yellowLightHover = Color(0xfffdf6db);
  static const Color yellowLightActive = Color(0xfffaebb2);
  static const Color yellowNormal = Color(0xfff0c000);
  static const Color yellowNormalHover = Color(0xffd8ad00);
  static const Color yellowNormalActive = Color(0xffc09a00);
  static const Color yellowDark = Color(0xffb49000);
  static const Color yellowDarkHover = Color(0xff907300);
  static const Color yellowDarkActive = Color(0xff6c5600);
  static const Color yellowDarker = Color(0xff544300);

  // --- Red ---
  static const Color redLight = Color(0xffffebeb);
  static const Color redLightHover = Color(0xffffe0e0);
  static const Color redLightActive = Color(0xffffbaba);
  static const Color redNormal = Color(0xffff4444);
  static const Color redNormalHover = Color(0xffe63d3d);
  static const Color redNormalActive = Color(0xffcc3636);
  static const Color redDark = Color(0xffbf3333);
  static const Color redDarkHover = Color(0xff992929);
  static const Color redDarkActive = Color(0xff731f1f);
  static const Color redDarker = Color(0xff591818);
}
