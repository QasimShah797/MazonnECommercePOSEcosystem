import 'package:flutter/material.dart';

/// Mazonn brand palette — warm ivory, charcoal, and muted gold.
abstract final class MazonnColors {
  static const Color noir = Color(0xFF1C1917);
  static const Color ink = Color(0xFF2C2622);
  static const Color ivory = Color(0xFFF7F4EF);
  static const Color cream = Color(0xFFF1EBE3);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gold = Color(0xFFB08968);
  static const Color goldDark = Color(0xFF8C6A48);
  static const Color goldSoft = Color(0xFFE8D5C0);
  static const Color stone = Color(0xFF7A736C);
  static const Color stoneLight = Color(0xFFB7B0A7);
  static const Color linen = Color(0xFFE7E0D6);
  static const Color success = Color(0xFF4F7A5A);
  static const Color error = Color(0xFFB14A3C);
  static const Color warning = Color(0xFFC08A3E);
  static const Color info = Color(0xFF4E6A74);
  static const Color overlay = Color(0x661C1917);

  static const LinearGradient splash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A2420), Color(0xFF1C1917)],
  );
}
