import 'package:flutter/material.dart';

abstract final class MazonnSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double page = 20;
}

abstract final class MazonnRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(lg));
  static const BorderRadius image = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

abstract final class MazonnShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> nav = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, -4),
    ),
  ];
}
