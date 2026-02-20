import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'NPS';

  /// 유지보수 포인트:
  /// Figma letterSpacing 값이 -5%라서 size * -0.05 로 환산합니다.
  static const double _letterSpacingPercent = -0.05;

  /// 유지보수 포인트:
  /// Figma lineHeight 100%를 Flutter의 height 1.0으로 고정합니다.
  static const double _lineHeight = 1.0;

  static const double _h1Size = 24;
  static const double _h2Size = 20;
  static const double _h3Size = 18;
  static const double _bodyLargeSize = 16;
  static const double _bodyMediumSize = 14;
  static const double _bodySmallSize = 12;
  static const double _captionSize = 12;

  static const TextStyle headingH1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: _h1Size,
    fontWeight: FontWeight.w800,
    height: _lineHeight,
    letterSpacing: _h1Size * _letterSpacingPercent,
  );

  static const TextStyle headingH2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: _h2Size,
    fontWeight: FontWeight.w800,
    height: _lineHeight,
    letterSpacing: _h2Size * _letterSpacingPercent,
  );

  static const TextStyle headingH3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: _h3Size,
    fontWeight: FontWeight.w700,
    height: _lineHeight,
    letterSpacing: _h3Size * _letterSpacingPercent,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: _bodyLargeSize,
    fontWeight: FontWeight.w400,
    height: _lineHeight,
    letterSpacing: _bodyLargeSize * _letterSpacingPercent,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: _bodyMediumSize,
    fontWeight: FontWeight.w400,
    height: _lineHeight,
    letterSpacing: _bodyMediumSize * _letterSpacingPercent,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: _bodySmallSize,
    fontWeight: FontWeight.w400,
    height: _lineHeight,
    letterSpacing: _bodySmallSize * _letterSpacingPercent,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: _captionSize,
    fontWeight: FontWeight.w700,
    height: _lineHeight,
    letterSpacing: _captionSize * _letterSpacingPercent,
  );

  /// 유지보수 포인트:
  /// 13개 타이포 노드와 토큰 연결 추적용 매핑입니다.
  static const Map<String, TextStyle> figmaNodeStyleMap = <String, TextStyle>{
    '88:68': headingH1,
    '89:3': headingH2,
    '89:7': headingH3,
    '89:12': bodyLarge,
    '89:13': bodyMedium,
    '89:14': bodySmall,
    '89:23': caption,
    '89:29': caption,
    '89:31': caption,
    '89:33': caption,
    '89:34': caption,
    '89:35': caption,
    '89:36': caption,
  };
}
