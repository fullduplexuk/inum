import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inum/presentation/design_system/colors.dart';

class AppTheme {
  AppTheme._();

  static final _baseTextStyle = GoogleFonts.getFont('Roboto');

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: inumPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: inumPrimary,
        primary: inumPrimary,
        secondary: inumSecondary,
        surface: white,
        surfaceContainerHighest: white,
        onSurface: black,
        onSurfaceVariant: secondaryTextColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: white,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: black),
        titleTextStyle: TextStyle(color: black, fontSize: 20, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(inumPrimary),
          foregroundColor: WidgetStateProperty.all(white),
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
          textStyle: WidgetStateProperty.all(_baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(inumPrimary),
          textStyle: WidgetStateProperty.all(_baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: customGreyColor400)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: customGreyColor400)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: inumPrimary)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: errorColor)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: errorColor)),
        hintStyle: _baseTextStyle.copyWith(color: customGreyColor600, fontSize: 16),
        labelStyle: _baseTextStyle.copyWith(color: black, fontSize: 16),
      ),
      textTheme: TextTheme(
        displayLarge: _baseTextStyle.copyWith(color: black, fontSize: 28, fontWeight: FontWeight.w700),
        displayMedium: _baseTextStyle.copyWith(color: black, fontSize: 24, fontWeight: FontWeight.w700),
        displaySmall: _baseTextStyle.copyWith(color: black, fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: _baseTextStyle.copyWith(color: black, fontSize: 20, fontWeight: FontWeight.w500),
        bodyMedium: _baseTextStyle.copyWith(color: black, fontSize: 16, fontWeight: FontWeight.w500),
        bodySmall: _baseTextStyle.copyWith(color: black, fontSize: 12, fontWeight: FontWeight.w400),
      ),
      iconTheme: const IconThemeData(color: black, size: 24),
      dividerTheme: const DividerThemeData(color: customGreyColor400, thickness: 1, space: 1),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: inumPrimary, selectionColor: inumPrimary, selectionHandleColor: inumPrimary,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: inumSecondary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: inumPrimary, brightness: Brightness.dark,
        primary: inumSecondary, secondary: inumPrimary,
        surface: darkSurface, onSurface: white, error: errorColor,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0, backgroundColor: darkSurface,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: transparent, statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(color: white),
        titleTextStyle: TextStyle(color: white, fontSize: 20, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(inumSecondary),
          foregroundColor: WidgetStateProperty.all(black),
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
          textStyle: WidgetStateProperty.all(_baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(inumSecondary),
          textStyle: WidgetStateProperty.all(_baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: customGreyColor700)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: customGreyColor700)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: inumSecondary)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: errorColor)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: errorColor)),
        hintStyle: _baseTextStyle.copyWith(color: customGreyColor500, fontSize: 16),
        labelStyle: _baseTextStyle.copyWith(color: white, fontSize: 16),
      ),
      textTheme: TextTheme(
        displayLarge: _baseTextStyle.copyWith(color: white, fontSize: 28, fontWeight: FontWeight.w700),
        displayMedium: _baseTextStyle.copyWith(color: white, fontSize: 24, fontWeight: FontWeight.w700),
        displaySmall: _baseTextStyle.copyWith(color: white, fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: _baseTextStyle.copyWith(color: white, fontSize: 20, fontWeight: FontWeight.w500),
        bodyMedium: _baseTextStyle.copyWith(color: white, fontSize: 16, fontWeight: FontWeight.w500),
        bodySmall: _baseTextStyle.copyWith(color: white, fontSize: 12, fontWeight: FontWeight.w400),
      ),
      iconTheme: const IconThemeData(color: white, size: 24),
      dividerTheme: const DividerThemeData(color: customGreyColor700, thickness: 1, space: 1),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: inumSecondary, selectionColor: inumSecondary, selectionHandleColor: inumSecondary,
      ),
    );
  }
}
