import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'game_assets.dart';
import 'game_controller.dart';

class GamePainter extends CustomPainter {
  GamePainter(this.controller, this.assets) : super(repaint: controller);

  final GameController controller;
  final GameAssets assets;

  // Reused every frame (Phase 10: avoid allocating in paint)
  final Paint _sky = Paint();
  final Paint _img = Paint()..filterQuality = FilterQuality.medium;
  final Paint _dirt = Paint()..color = const Color(0xFFDED895);
  final Paint _debug = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Random _rnd = Random();

  // Sky gradient shader is cached; it only changes when the size changes
  Size? _skySize;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _applyShake(canvas, size);

    _drawSky(canvas, size);
    _drawTiledLayer(
      canvas,
      size,
      assets.clouds,
      top: size.height * GameConstants.cloudsTop,
      height: size.height * GameConstants.cloudsHeight,
      parallax: GameConstants.cloudsParallax,
    );
    _drawTiledLayer(
      canvas,
      size,
      assets.hills,
      top: size.height * GameConstants.groundTop -
          size.height * GameConstants.hillsHeight,
      height: size.height * GameConstants.hillsHeight,
      parallax: GameConstants.hillsParallax,
    );
    _drawPipes(canvas, size);
    _drawTiledLayer(
      // Ground covers the bottom of the pipes
      canvas,
      size,
      assets.ground,
      top: size.height * GameConstants.groundTop,
      height: size.height * GameConstants.groundHeight,
      parallax: GameConstants.groundParallax,
    );
    // Dirt colour below the screen edge so screen shake never shows a gap
    canvas.drawRect(
      Rect.fromLTWH(-40, size.height - 1, size.width + 80, 41),
      _dirt,
    );
    _drawBird(canvas, size);
    if (controller.debug) _drawDebug(canvas, size);

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

  // -------------------------------------------------------------------- Sky

  void _drawSky(Canvas canvas, Size size) {
    // Bigger than the screen so screen shake never reveals an empty edge
    final rect = (Offset.zero & size).inflate(40);
    if (_skySize != size) {
      _skySize = size;
      _sky.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4EC0CA), Color(0xFFB8E8F0)],
      ).createShader(Offset.zero & size);
    }
    canvas.drawRect(rect, _sky);
  }

  // --------------------------------------------------------- Scrolling layers

  /// Draws [image] repeated horizontally, scaled to [height], and scrolled by
  /// the world scroll * [parallax]. parallax 1.0 = same speed as the pipes;
  /// smaller values move slower, which gives the depth effect.
  void _drawTiledLayer(
    Canvas canvas,
    Size size,
    ui.Image image, {
    required double top,
    required double height,
    required double parallax,
  }) {
    final scale = height / image.height;
    final tileW = image.width * scale;
    final src =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    final offsetPx = (controller.scroll * parallax * size.width) % tileW;
    var x = -offsetPx - 40; // start a bit left so shake never shows a gap
    while (x < size.width + 40) {
      // +1 px overlap between tiles hides hairline seams
      canvas.drawImageRect(
          image, src, Rect.fromLTWH(x, top, tileW + 1, height), _img);
      x += tileW;
    }
  }

  // ------------------------------------------------------------------ Pipes

  void _drawPipes(Canvas canvas, Size size) {
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
      canvas.drawImageRect(body, bodySrc, top.inflate(0.5), _img);
      canvas.drawImageRect(body, bodySrc, bottom.inflate(0.5), _img);

      // Caps at the gap end of each pipe (same width as the hitbox)
      canvas.drawImageRect(
        capTop,
        capTopSrc,
        Rect.fromLTRB(top.left, top.bottom - capH, top.right, top.bottom),
        _img,
      );
      canvas.drawImageRect(
        capBottom,
        capBottomSrc,
        Rect.fromLTRB(bottom.left, bottom.top, bottom.right, bottom.top + capH),
        _img,
      );
    }
  }

  // ------------------------------------------------------------------- Bird

  void _drawBird(Canvas canvas, Size size) {
    final bird = controller.bird;
    final r = controller.birdRadiusPx;
    final center =
        Offset(size.width * GameConstants.birdX, bird.y * size.height);

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
      _img,
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
