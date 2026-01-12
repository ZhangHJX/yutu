import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme() => ThemeData(
    primaryColor: const Color(0xFF9ADEFD),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: const Color(0xFF9ADEFD),
      selectionColor: const Color(0xFFFAC209),
    ),
    appBarTheme: AppBarTheme(
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: .dark.copyWith(statusBarColor: Colors.transparent),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: TextStyle(fontSize: 17, color: Color(0xFF232535)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      alignLabelWithHint: true,
      hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
      contentPadding: .zero,
    ),
    scaffoldBackgroundColor: Color(0xFFF5F5F5),
  );
}
