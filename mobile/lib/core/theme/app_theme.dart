import 'package:flutter/material.dart';

class AppTheme {
  static const forest = Color(0xff061827);
  static const navy = Color(0xff082744);
  static const royalBlue = Color(0xff07559d);
  static const gold = Color(0xffe4c16c);
  static const parchment = Color(0xfffff1cf);
  static const ink = Color(0xff352819);

  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: const BorderSide(color: gold));
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
          primary: gold,
          onPrimary: ink,
          secondary: Color(0xff75e8ed),
          surface: navy,
          onSurface: parchment),
      scaffoldBackgroundColor: forest,
      textTheme: base.textTheme.apply(bodyColor: parchment, displayColor: gold),
      appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
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
              backgroundColor: royalBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xff344755),
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
          fillColor: const Color(0xee082744),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: gold))),
      chipTheme: base.chipTheme.copyWith(
          backgroundColor: forest,
          selectedColor: royalBlue,
          side: const BorderSide(color: gold),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
      dialogTheme: DialogTheme(
          backgroundColor: const Color(0xff0c151c),
          surfaceTintColor: Colors.transparent,
          shape: shape),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xff69ebed),
          linearTrackColor: Color(0xff173851),
          linearMinHeight: 7),
      listTileTheme:
          const ListTileThemeData(iconColor: gold, textColor: parchment),
    );
  }
}
