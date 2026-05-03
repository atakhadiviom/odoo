import 'package:flutter/material.dart';

ThemeData buildAppTheme({Color? primaryColor, Color? accentColor}) {
  final seedColor = primaryColor ?? const Color(0xFFC65D3D);
  final secondarySeed = accentColor ?? const Color(0xFF182126);

  const background = Color(0xFFFBF9F7);
  const surface = Colors.white;
  const ink = Color(0xFF182126);

  final scheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
    background: background,
    surface: surface,
  ).copyWith(
    primary: seedColor,
    onPrimary: Colors.white,
    secondary: secondarySeed,
    onSurface: ink,
    outlineVariant: const Color(0xFFE5DED5),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSans',
    fontFamilyFallback: const ['NotoSansSymbols2'],
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withOpacity(0.5),
      space: 1,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: seedColor, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}
