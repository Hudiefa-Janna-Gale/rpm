import 'package:flutter/material.dart';

/// Transcribed from the supplied RPM Foundations and Flutter contract.
abstract final class RpmTokens {
  static const background = Color(0xFF0D1729);
  static const sidebar = Color(0xFF101A30);
  static const card = Color(0xFF172642);
  static const primary = Color(0xFF536DFE);
  static const accent = Color(0xFF8294FF);
  static const text = Color(0xFFF4F6FF);
  static const secondary = Color(0xFF9CAAC2);
  static const border = Color(0xFF2C3D5A);
  static const hover = Color(0xFF203454);
  static const selected = Color(0xFF27365D);
  static const success = Color(0xFF61D4B1);
  static const danger = Color(0xFFFF8296);
  static const warning = Color(0xFFF3BD58);
  static const dangerSurface = Color(0xFF3C263B);
  static const warningSurface = Color(0xFF3A3428);
  static const sidebarWidth = 224.0;
  static const collapsedWidth = 72.0;
  static const controlHeight = 40.0;
  static const rowHeight = 56.0;
  static const controlRadius = 8.0;
  static const cardRadius = 12.0;
  static const hoverDuration = Duration(milliseconds: 120);
  static const pressDuration = Duration(milliseconds: 80);
  static const collapseDuration = Duration(milliseconds: 200);
  static const moneyStyle = TextStyle(
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static double pageInset(double width) => width >= 1440 ? 32 : 24;
}

/// Light compatibility mode preserves the existing application's theme feature.
/// The supplied design defines the dark palette; its exact values live above.
class RpmPalette {
  final bool dark;
  const RpmPalette(this.dark);
  Color get background => dark ? RpmTokens.background : const Color(0xFFF4F6FA);
  Color get sidebar => dark ? RpmTokens.sidebar : Colors.white;
  Color get card => dark ? RpmTokens.card : Colors.white;
  Color get text => dark ? RpmTokens.text : const Color(0xFF172238);
  Color get secondary => dark ? RpmTokens.secondary : const Color(0xFF60708A);
  Color get border => dark ? RpmTokens.border : const Color(0xFFDCE2ED);
  Color get hover => dark ? RpmTokens.hover : const Color(0xFFEBEFFF);
  Color get selected => dark ? RpmTokens.selected : const Color(0xFFE2E7FF);
  Color get accent => dark ? RpmTokens.accent : const Color(0xFF4159D8);
  Color get success => dark ? RpmTokens.success : const Color(0xFF117C60);
  Color get danger => dark ? RpmTokens.danger : const Color(0xFFBC304B);
  Color get warning => dark ? RpmTokens.warning : const Color(0xFF93630E);
  Color get dangerSurface =>
      dark ? RpmTokens.dangerSurface : const Color(0xFFFFEAF0);
  Color get warningSurface =>
      dark ? RpmTokens.warningSurface : const Color(0xFFFFF3DB);
}

extension RpmDesignContext on BuildContext {
  RpmPalette get rpm =>
      RpmPalette(Theme.of(this).brightness == Brightness.dark);
}
