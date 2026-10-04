import 'package:flutter/material.dart';

class AppTheme {
  static const forest = Color(0xff0b201f);
  static const gold = Color(0xffd5b574);
  static const parchment = Color(0xffeddbb6);
  static const ink = Color(0xff30281d);

  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: const BorderSide(color: gold));
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
          primary: gold,
          onPrimary: ink,
          secondary: Color(0xff79c8b3),
          surface: Color(0xff142e2b),
          onSurface: Color(0xfff3e8d0)),
      scaffoldBackgroundColor: forest,
      textTheme: base.textTheme.apply(bodyColor: parchment, displayColor: gold),
      appBarTheme: const AppBarTheme(
          backgroundColor: forest,
          foregroundColor: gold,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5)),
      dividerTheme: const DividerThemeData(color: Color(0xff6f6040), space: 28),
      iconTheme: const IconThemeData(color: gold),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff1c5146),
              foregroundColor: const Color(0xffffe4a6),
              disabledBackgroundColor: const Color(0xff384740),
              disabledForegroundColor: const Color(0xffc2bba9),
              minimumSize: const Size(48, 54),
              shape: shape,
              textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              foregroundColor: gold,
              minimumSize: const Size(48, 50),
              shape: shape,
              side: const BorderSide(color: gold))),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              foregroundColor: gold, minimumSize: const Size(48, 48))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xff132d2a),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: gold))),
      chipTheme: base.chipTheme.copyWith(
          backgroundColor: forest,
          selectedColor: const Color(0xff396051),
          side: const BorderSide(color: gold),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
      dialogTheme: DialogTheme(
          backgroundColor: const Color(0xff0c151c),
          surfaceTintColor: Colors.transparent,
          shape: shape),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xff72cbbb),
          linearTrackColor: Color(0xff263d36),
          linearMinHeight: 7),
      listTileTheme:
          const ListTileThemeData(iconColor: gold, textColor: parchment),
    );
  }
}
