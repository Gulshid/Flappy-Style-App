import 'dart:ui';

import '../utils/constants.dart';

/// One look of the sky. The game blends smoothly between palettes.
///
///  - [top] / [bottom]  the sky gradient
///  - [tint]            multiplied over clouds, hills, pipes and ground
///                      (white = unchanged, bluish = night)
///  - [stars]           0 = no stars, 1 = full night sky with the moon
class SkyPalette {
  const SkyPalette({
    required this.top,
    required this.bottom,
    required this.tint,
    required this.stars,
  });

  final Color top;
  final Color bottom;
  final Color tint;
  final double stars;

  static const SkyPalette day = SkyPalette(
    top: Color(0xFF4EC0CA),
    bottom: Color(0xFFB8E8F0),
    tint: Color(0xFFFFFFFF),
    stars: 0,
  );

  static const SkyPalette sunset = SkyPalette(
    top: Color(0xFF5B4B8A),
    bottom: Color(0xFFFFB27A),
    tint: Color(0xFFFFD9C2),
    stars: 0.1,
  );

  static const SkyPalette night = SkyPalette(
    top: Color(0xFF0B1B3A),
    bottom: Color(0xFF2B4C7E),
    tint: Color(0xFF7C8CC0),
    stars: 1,
  );

  static const SkyPalette dawn = SkyPalette(
    top: Color(0xFF6FA8DC),
    bottom: Color(0xFFF7C9A9),
    tint: Color(0xFFE8EEFF),
    stars: 0.25,
  );

  /// The order the sky moves through as the score grows.
  static const List<SkyPalette> stages = [day, sunset, night, dawn];

  /// Which palette belongs to [score] (changes every skyStageLength points).
  static SkyPalette forScore(int score) =>
      stages[(score ~/ GameConstants.skyStageLength) % stages.length];

  static SkyPalette lerp(SkyPalette a, SkyPalette b, double t) => SkyPalette(
        top: Color.lerp(a.top, b.top, t)!,
        bottom: Color.lerp(a.bottom, b.bottom, t)!,
        tint: Color.lerp(a.tint, b.tint, t)!,
        stars: a.stars + (b.stars - a.stars) * t,
      );
}
