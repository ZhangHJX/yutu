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
      systemOverlayStyle: .dark.copyWith(statusBarColor: Colors.transparent),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: cff333333,
      elevation: 2,
      titleTextStyle: .new(fontSize: 17, color: cff333333, fontFamily: 'NotoSansSC'),
    ),
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cffedeee)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cffedeee)),
      alignLabelWithHint: true,
      hintStyle: .new(color: cffb8b8b8),
      contentPadding: .zero,
    ),
    scaffoldBackgroundColor: Color(0xFFF7F9FE),
    fontFamily: 'NotoSansSC',
  );

  static ThemeData darkTheme() {
    const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: .light,
      statusBarIconBrightness: .light,
    );

    return ThemeData(
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: const Color(0xFFFAC209),
        selectionColor: const Color(0xFFFAC209),
      ),
      appBarTheme: AppBarTheme(
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlayStyle,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.amber,
        elevation: 2,
        titleTextStyle: const .new(fontSize: 17, color: Color(0xff121212), fontWeight: .bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cffedeee)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cffedeee)),
        alignLabelWithHint: true,
        hintStyle: .new(color: cffb8b8b8),
        contentPadding: .zero,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F9FE),
      fontFamily: 'NotoSansSC',
    );
  }
}
