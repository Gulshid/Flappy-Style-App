import 'dart:math';

import 'package:flutter/material.dart';

import '../models/skin.dart';
import '../utils/constants.dart';
import 'game_assets.dart';
import 'game_controller.dart';
import 'layers.dart';
import 'particles.dart';
import 'sky_renderer.dart';

class GamePainter extends CustomPainter {
  GamePainter(
    this.controller,
    this.assets, {
    BirdSkin skin = BirdSkin.classic,
  }) : super(repaint: controller) {
    _birdPaint.colorFilter = skin.filter;
  }

  final GameController controller;
  final GameAssets assets;

  // Reused every frame: nothing is allocated in paint() unless needed
  final SkyRenderer _skyRenderer = SkyRenderer();
  final Paint _birdPaint = Paint()..filterQuality = FilterQuality.medium;
  final Paint _dirt = Paint();
  final Paint _particle = Paint();
  final Paint _flash = Paint();
  final Paint _debug = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Random _rnd = Random();

  static const Color _dirtDay = Color(0xFFDED895);
  static const Color _dirtNight = Color(0xFF3A4260);

  @override
  void paint(Canvas canvas, Size size) {
    final sky = controller.sky;

    canvas.save();
    _applyShake(canvas, size);

    _skyRenderer.paint(canvas, size, sky, controller.animTime);
    final layer = _skyRenderer.layer; // tinted by the current sky

    drawTiledLayer(
      canvas,
      size,
      assets.clouds,
      layer,
      top: size.height * GameConstants.cloudsTop,
      height: size.height * GameConstants.cloudsHeight,
      offset: controller.scroll * GameConstants.cloudsParallax * size.width,
    );
    drawTiledLayer(
      canvas,
      size,
      assets.hills,
      layer,
      top: size.height * GameConstants.groundTop -
          size.height * GameConstants.hillsHeight,
      height: size.height * GameConstants.hillsHeight,
      offset: controller.scroll * GameConstants.hillsParallax * size.width,
    );
    _drawPipes(canvas, size, layer);
    drawTiledLayer(
      // Ground covers the bottom of the pipes
      canvas,
      size,
      assets.ground,
      layer,
      top: size.height * GameConstants.groundTop,
      height: size.height * GameConstants.groundHeight,
      offset: controller.scroll * GameConstants.groundParallax * size.width,
    );

    // Dirt colour below the screen edge so screen shake never shows a gap
    _dirt.color = Color.lerp(_dirtDay, _dirtNight, sky.stars)!;
    canvas.drawRect(
      Rect.fromLTWH(-40, size.height - 1, size.width + 80, 41),
      _dirt,
    );

    _drawParticles(canvas);
    _drawBird(canvas, size);
    if (controller.debug) _drawDebug(canvas, size);
    _drawFlash(canvas, size);

    canvas.restore();
  }

  // ------------------------------------------------------------------ Shake

  void _applyShake(Canvas canvas, Size size) {
    final s = controller.shake;
    if (s <= 0) return;
    final m = size.width * GameConstants.shakeMagnitude * s;
    canvas.translate(
      (_rnd.nextDouble() - 0.5) * 2 * m,
      (_rnd.nextDouble() - 0.5) * 2 * m,
    );
  }

  /// A very short white flash right after a crash.
  void _drawFlash(Canvas canvas, Size size) {
    final f = ((controller.shake - 0.6) / 0.4).clamp(0.0, 1.0).toDouble();
    if (f <= 0) return;
    _flash.color =
        Colors.white.withAlpha((255 * f * GameConstants.flashStrength).round());
    canvas.drawRect((Offset.zero & size).inflate(40), _flash);
  }

  // ------------------------------------------------------------------ Pipes

  void _drawPipes(Canvas canvas, Size size, Paint paint) {
    final pw = controller.pipeWidthPx;
    final capH = size.height * GameConstants.pipeCapHeight;
    final body = assets.pipeBody;
    final bodySrc =
        Rect.fromLTWH(0, 0, body.width.toDouble(), body.height.toDouble());
    final capTop = assets.pipeCapTop;
    final capBottom = assets.pipeCapBottom;
    final capTopSrc = Rect.fromLTWH(
        0, 0, capTop.width.toDouble(), capTop.height.toDouble());
    final capBottomSrc = Rect.fromLTWH(
        0, 0, capBottom.width.toDouble(), capBottom.height.toDouble());

    for (final p in controller.pipes) {
      final top = p.topRect(size, pw);
      final bottom = p.bottomRect(size, pw);

      // Bodies (stretched vertically; the shading is horizontal so it stays crisp)
      canvas.drawImageRect(body, bodySrc, top.inflate(0.5), paint);
      canvas.drawImageRect(body, bodySrc, bottom.inflate(0.5), paint);

      // Caps at the gap end of each pipe (same width as the hitbox)
      canvas.drawImageRect(
        capTop,
        capTopSrc,
        Rect.fromLTRB(top.left, top.bottom - capH, top.right, top.bottom),
        paint,
      );
      canvas.drawImageRect(
        capBottom,
        capBottomSrc,
        Rect.fromLTRB(bottom.left, bottom.top, bottom.right, bottom.top + capH),
        paint,
      );
    }
  }

  // -------------------------------------------------------------- Particles

  void _drawParticles(Canvas canvas) {
    for (final p in controller.particles.items) {
      final t = p.t;
      switch (p.kind) {
        case ParticleKind.puff:
          _particle.color = p.color.withAlpha((170 * t).round());
          canvas.drawCircle(Offset(p.x, p.y), p.size * (1.6 - 0.6 * t), _particle);
        case ParticleKind.spark:
          _particle.color = p.color.withAlpha((255 * t).round());
          final s = p.size * (0.4 + 0.6 * t);
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.rotation);
          // A rotated square reads as a small diamond sparkle
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: s * 2, height: s * 2),
            _particle,
          );
          canvas.restore();
        case ParticleKind.feather:
          _particle.color = p.color.withAlpha((255 * t).round());
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.rotation);
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset.zero, width: p.size * 2.4, height: p.size * 0.9),
            _particle,
          );
          canvas.restore();
      }
    }
  }

  // ------------------------------------------------------------------- Bird

  void _drawBird(Canvas canvas, Size size) {
    final bird = controller.bird;
    final r = controller.birdRadiusPx;
    final center = controller.birdCenter;

    // Wing animation by time: 10 fps through the frame sequence
    final seq = GameConstants.wingSequence;
    final index =
        (controller.animTime * GameConstants.wingFps).floor() % seq.length;
    final frame = assets.birdFrames[seq[index]];

    final w = r * GameConstants.birdSpriteWidthFactor;
    final h = w * frame.height / frame.width;
    final src =
        Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble());

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(bird.angle); // nose up / nose down
    canvas.drawImageRect(
      frame,
      src,
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      _birdPaint,
    );
    canvas.restore();
  }

  // ------------------------------------------------------------------ Debug

  /// Draws the exact rects used for collision (single source of truth:
  /// the controller's birdRect and the Pipe rects).
  void _drawDebug(Canvas canvas, Size size) {
    canvas.drawRect(controller.birdRect, _debug);

    final pw = controller.pipeWidthPx;
    for (final p in controller.pipes) {
      canvas.drawRect(p.topRect(size, pw), _debug);
      canvas.drawRect(p.bottomRect(size, pw), _debug);
    }

    // Ground line
    final groundY = GameConstants.groundTop * size.height;
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY), _debug);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => false;
  // Repaints are driven by `repaint: controller`, not by shouldRepaint.
}
