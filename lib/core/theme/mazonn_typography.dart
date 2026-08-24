import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mazonn_colors.dart';

abstract final class MazonnTypography {
  static TextTheme textTheme() {
    final display = GoogleFonts.playfairDisplay(
      color: MazonnColors.noir,
      height: 1.2,
    );
    final body = GoogleFonts.plusJakartaSans(
      color: MazonnColors.ink,
      height: 1.45,
    );

    return TextTheme(
      displayLarge: display.copyWith(fontSize: 40, fontWeight: FontWeight.w600),
      displayMedium: display.copyWith(fontSize: 32, fontWeight: FontWeight.w600),
      displaySmall: display.copyWith(fontSize: 26, fontWeight: FontWeight.w600),
      headlineLarge: display.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
      headlineMedium: display.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: display.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: body.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: body.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: body.copyWith(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: body.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: body.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: MazonnColors.stone,
      ),
      labelLarge: body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
      labelMedium: body.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      labelSmall: body.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.4,
        color: MazonnColors.stone,
      ),
    );
  }
}
