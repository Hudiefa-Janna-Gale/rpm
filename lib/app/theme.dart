import 'package:flutter/material.dart';
import '../design/tokens.dart';

// Compatibility aliases for the existing startup and recovery views.
const navy = RpmTokens.sidebar;
const purple = RpmTokens.primary;
const green = RpmTokens.success;

ThemeData rpmTheme(Brightness brightness) {
  final p = RpmPalette(brightness == Brightness.dark);
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(RpmTokens.controlRadius),
        borderSide: BorderSide(color: color, width: width),
      );
  final scheme =
      ColorScheme.fromSeed(
        seedColor: RpmTokens.primary,
        brightness: brightness,
      ).copyWith(
        primary: RpmTokens.primary,
        onPrimary: RpmTokens.text,
        surface: p.sidebar,
        onSurface: p.text,
        onSurfaceVariant: p.secondary,
        outline: p.border,
        outlineVariant: p.border,
        error: p.danger,
      );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: p.background,
    dividerColor: p.border,
    visualDensity: VisualDensity.standard,
    textTheme: TextTheme(
      displaySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: p.text,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.15,
        color: p.text,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: p.text,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: p.text,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        height: 1.5,
        color: p.text,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        height: 1.5,
        color: p.text,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        height: 1.5,
        color: p.secondary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        color: p.secondary,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: p.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      hintStyle: TextStyle(fontSize: 14, color: p.secondary),
      labelStyle: TextStyle(color: p.secondary),
      border: WidgetStateInputBorder.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return border(p.border.withValues(alpha: .6));
        }
        if (states.contains(WidgetState.error)) {
          return border(p.danger, states.contains(WidgetState.focused) ? 2 : 1);
        }
        if (states.contains(WidgetState.focused)) return border(p.accent, 2);
        return border(
          states.contains(WidgetState.hovered) ? p.secondary : p.border,
        );
      }),
      errorStyle: TextStyle(color: p.danger, fontSize: 11),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        backgroundColor: RpmTokens.primary,
        foregroundColor: p.text,
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        foregroundColor: p.text,
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.sidebar,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: p.text,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.border),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.card,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(fontFamily: 'Inter', color: p.text, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: p.border),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: p.secondary,
      ),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(p.card),
      dataRowColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered) ? p.hover : p.sidebar,
      ),
      dataTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: p.secondary,
      ),
      headingTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: p.secondary,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(p.secondary.withValues(alpha: .35)),
      radius: const Radius.circular(4),
      thickness: const WidgetStatePropertyAll(5),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: p.card,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, color: p.text),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: RpmTokens.primary.withValues(alpha: .3),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? RpmTokens.text : p.text,
      ),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? RpmTokens.primary
            : Colors.transparent,
      ),
    ),
  );
}
