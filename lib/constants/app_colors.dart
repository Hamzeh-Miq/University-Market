import 'package:flutter/material.dart';

/// Central color palette for UniTrade
class AppColors {
  AppColors._();

  // Primary brand color
  static const Color primary = Color(0xFF1E78FF);
  static const Color primaryDark = Color(0xFF0B1E43);
  static const Color primaryLight = Color(0xFFE7F0FF);

  // Authentication depth colors
  static const Color authNavyDeep = Color(0xFF0A1628);
  static const Color authNavyMid = Color(0xFF0F2044);
  static const Color authNavyBright = Color(0xFF132D5C);
  static const Color authNavy = Color(0xFF0B1E43);
  static const Color authBlue = Color(0xFF1A3668);
  static const Color authHighlight = Color(0xFF4FA3FF);
  static const Color glassFill = Color(0x26FFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);

  // Accent
  static const Color accent = Color(0xFF00BFA5);
  static const Color favourite = Color(0xFFE93D68);
  static const Color amber = Color(0xFFF59E0B);

  // Backgrounds
  static const Color background = Color(0xFFF4F6F9);
  static const Color surface = Colors.white;
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color softSurface = Color(0xFFF8FAFD);
  static const Color chipBackground = Color(0xFFEFF3F8);

  // Text
  static const Color textPrimary = Color(0xFF1A2340);
  static const Color textSecondary = Color(0xFF6B7897);
  static const Color textHint = Color(0xFFB0BAD3);

  // Status
  static const Color success = Color(0xFF43A047);
  static const Color successLight = Color(0xFF66BB6A);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB300);

  // Dark-surface foregrounds and overlays
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryMuted = Color(0xB3FFFFFF);
  static const Color onPrimarySoft = Color(0xA6FFFFFF);
  static const Color onPrimarySubtle = Color(0x8CFFFFFF);
  static const Color onPrimaryFaint = Color(0x33FFFFFF);
  static const Color onPrimaryDivider = Color(0x3DFFFFFF);
  static const Color subtleBlackShadow = Color(0x0D000000);

  // Divider & border
  static const Color divider = Color(0xFFE8EDF5);
  static const Color border = Color(0xFFD0D9EC);
  static const Color shadow = Color(0x1A0B1E43);

  /// Standard radius for primary cards, fields, sheets, and image clips.
  static const double radius = 16;

  /// Brand gradient used for primary actions.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, authHighlight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Deep immersive gradient for authentication surfaces.
  static const LinearGradient authGradient = LinearGradient(
    colors: [authNavy, authBlue],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Soft product/banner gradient used inside the app canvas.
  static const LinearGradient softBlueGradient = LinearGradient(
    colors: [Color(0xFFEAF2FF), Color(0xFFF8FBFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
