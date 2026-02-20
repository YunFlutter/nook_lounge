import 'package:flutter/animation.dart';

class AppMotion {
  const AppMotion._();

  static const Duration screen = Duration(milliseconds: 320);
  static const Duration element = Duration(milliseconds: 220);
  static const Duration press = Duration(milliseconds: 120);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOut;
}
