import 'package:flutter/material.dart';

/// Base colors
const Color white = Colors.white;
const Color black = Colors.black;
const Color transparent = Colors.transparent;
const Color errorColor = Colors.red;
const Color successColor = Colors.green;
const Color customOrangeColor = Colors.orange;

/// INUM brand colors
const Color inumPrimary = Color(0xFF1E3A5F);
const Color inumSecondary = Color(0xFF00BCD4);

/// Legacy aliases
const Color customIndigoColor = inumPrimary;
const Color customIndigoColorSecondary = inumSecondary;

/// Background colors
const Color backgroundGrey = Color.fromRGBO(245, 247, 250, 1);

/// White with opacity variants
const Color whiteWithOpacity30 = Color.fromRGBO(255, 255, 255, 0.3);
const Color whiteWithOpacity10 = Color.fromRGBO(255, 255, 255, 0.1);
const Color whiteWithOpacity12 = Color.fromRGBO(255, 255, 255, 0.12);

/// Grey color scale
const Color customGreyColor900 = Color.fromRGBO(33, 33, 33, 1);
const Color customGreyColor800 = Color.fromRGBO(66, 66, 66, 1);
const Color customGreyColor700 = Color.fromRGBO(97, 97, 97, 1);
const Color customGreyColor600 = Color.fromRGBO(117, 117, 117, 1);
const Color customGreyColor500 = Color.fromRGBO(158, 158, 158, 1);
const Color customGreyColor400 = Color.fromRGBO(189, 189, 189, 1);
const Color customGreyColor300 = Color.fromRGBO(224, 224, 224, 1);
const Color customGreyColor200 = Color.fromRGBO(238, 238, 238, 1);

/// Text colors
const Color secondaryTextColor = Color.fromRGBO(100, 100, 100, 1);
const Color disabledTextColor = customGreyColor500;

/// Dark theme colors
const Color darkBackground = Color(0xFF121212);
const Color darkSurface = Color(0xFF1E1E1E);
const Color darkCard = Color(0xFF2C2C2C);

/// Button gradient colors
const Color buttonGradientActiveStart = inumPrimary;
const Color buttonGradientActiveEnd = inumSecondary;
const Color buttonGradientInactiveStart = customGreyColor400;
const Color buttonGradientInactiveEnd = customGreyColor600;
