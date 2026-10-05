import 'dart:math';

import 'package:flutter/material.dart';

import 'sky_palette.dart';

class _Star {
  const _Star(this.x, this.y, this.radius, this.phase);
  final double x; // 0..1 of the width
  final double y; // 0..1 of the sky area
  final double radius; // design px
  final double phase;
}

/// Paints the sky: gradient, twinkling stars and the moon. It also owns the
/// [layer] paint that tints the sprites (clouds, hills, pipes, ground).
/// Shared by the game and the menu background; keeps its own caches so
/// nothing is allocated per frame unless the colours are changing.
class SkyRenderer {
  final Paint _sky = Paint();
  final Paint _star = Paint();
  final Paint _moon = Paint();

  /// Use this paint for every sprite so the day/night tint applies.
  final Paint layer = Paint()..filterQuality = FilterQuality.medium;

  Size? _size;
  Color? _top;
  Color? _bottom;
  Color? _tint;

  late final List<_Star> _stars = () {
    final rnd = Random(42);
    return List<_Star>.generate(
      46,
      (_) => _Star(
        rnd.nextDouble(),
        rnd.nextDouble() * 0.6,
        0.7 + rnd.nextDouble() * 1.5,
        rnd.nextDouble() * 6.28,
      ),
    );
  }();

  void paint(Canvas canvas, Size size, SkyPalette sky, double time) {
    _syncTint(sky.tint);

    // Gradient shader is cached; rebuilt only when colours or size change.
    if (_size != size || _top != sky.top || _bottom != sky.bottom) {
      _size = size;
      _top = sky.top;
      _bottom = sky.bottom;
      _sky.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [sky.top, sky.bottom],
      ).createShader(Offset.zero & size);
    }
    // Bigger than the screen so screen shake never reveals an empty edge
    canvas.drawRect((Offset.zero & size).inflate(40), _sky);

    if (sky.stars > 0.02) {
      _drawStars(canvas, size, sky.stars, time);
      _drawMoon(canvas, size, sky.stars);
    }
  }

  void _syncTint(Color tint) {
    if (_tint == tint) return;
    _tint = tint;
    layer.colorFilter = ColorFilter.mode(tint, BlendMode.modulate);
  }

  void _drawStars(Canvas canvas, Size size, double amount, double time) {
    final k = size.width / 360;
    for (final s in _stars) {
      final twinkle = 0.55 + 0.45 * sin(time * 2.0 + s.phase);
      _star.color = Colors.white.withAlpha((255 * amount * twinkle).round());
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius * k,
        _star,
      );
    }
  }

  void _drawMoon(Canvas canvas, Size size, double amount) {
    final c = Offset(size.width * 0.78, size.height * 0.13);
    final r = size.width * 0.06;
    // Soft glow: three discs with falling opacity
    _moon.color = const Color(0xFFFFF6D6).withAlpha((28 * amount).round());
    canvas.drawCircle(c, r * 2.6, _moon);
    _moon.color = const Color(0xFFFFF6D6).withAlpha((48 * amount).round());
    canvas.drawCircle(c, r * 1.7, _moon);
    _moon.color = const Color(0xFFFFF6D6).withAlpha((235 * amount).round());
    canvas.drawCircle(c, r, _moon);
  }
}
