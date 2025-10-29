import 'package:common/src/config/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static ThemeData lightTheme() => ThemeData(
    primaryColor: const Color(0xFFFAC209),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: const Color(0xFFFAC209),
      selectionColor: const Color(0xFFFAC209),
    ),
    appBarTheme: AppBarTheme(
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: cff333333,
      elevation: 2,
      titleTextStyle: TextStyle(fontSize: 17, color: cff333333, fontFamily: 'NotoSansSC'),
    ),
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cffedeee)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cffedeee)),
      alignLabelWithHint: true,
      hintStyle: TextStyle(color: cffb8b8b8),
      contentPadding: EdgeInsets.zero,
    ),
    scaffoldBackgroundColor: Color(0xFFF7F9FE),
    fontFamily: 'NotoSansSC',
  );

  static ThemeData darkTheme() {
    const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    );

    return ThemeData(
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: const Color(0xFFFAC209),
        selectionColor: const Color(0xFFFAC209),
      ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: overlayStyle,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.amber,
        elevation: 2,
        titleTextStyle: const TextStyle(
          fontSize: 17,
          color: Color(0xff121212),
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cffedeee)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cffedeee)),
        alignLabelWithHint: true,
        hintStyle: TextStyle(color: cffb8b8b8),
        contentPadding: EdgeInsets.zero,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F9FE),
      fontFamily: 'NotoSansSC',
    );
  }
}
