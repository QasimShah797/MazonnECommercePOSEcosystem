import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mazonn_colors.dart';
import 'mazonn_metrics.dart';
import 'mazonn_typography.dart';

abstract final class MazonnTheme {
  static ThemeData light() {
    final textTheme = MazonnTypography.textTheme();
    const scheme = ColorScheme.light(
      primary: MazonnColors.noir,
      onPrimary: MazonnColors.white,
      secondary: MazonnColors.gold,
      onSecondary: MazonnColors.white,
      surface: MazonnColors.white,
      onSurface: MazonnColors.ink,
      error: MazonnColors.error,
      onError: MazonnColors.white,
      outline: MazonnColors.linen,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: MazonnColors.ivory,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: MazonnColors.ivory,
        foregroundColor: MazonnColors.noir,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleMedium?.copyWith(color: MazonnColors.noir),
      ),
      dividerTheme: const DividerThemeData(
        color: MazonnColors.linen,
        space: 1,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: MazonnColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: MazonnRadius.card),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MazonnColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(color: MazonnColors.stoneLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MazonnRadius.md),
          borderSide: const BorderSide(color: MazonnColors.linen),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MazonnRadius.md),
          borderSide: const BorderSide(color: MazonnColors.linen),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MazonnRadius.md),
          borderSide: const BorderSide(color: MazonnColors.noir, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MazonnRadius.md),
          borderSide: const BorderSide(color: MazonnColors.error),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: MazonnColors.stoneLight),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return MazonnColors.noir;
          return MazonnColors.white;
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: MazonnColors.white,
        shape: RoundedRectangleBorder(borderRadius: MazonnRadius.sheet),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MazonnColors.noir,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: MazonnColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MazonnRadius.sm)),
      ),
    );
  }
}
