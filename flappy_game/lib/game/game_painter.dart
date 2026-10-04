import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'game_controller.dart';

class GamePainter extends CustomPainter {
  final GameController controller;

  // Reused every frame (Phase 10: avoid allocating in paint)
  final Paint _sky = Paint();
  final Paint _ground = Paint()..color = const Color(0xFFDED895);
  final Paint _grass = Paint()..color = const Color(0xFF73BF2E);
  final Paint _body = Paint()..color = const Color(0xFFFFD54F);
  final Paint _eyeWhite = Paint()..color = Colors.white;
  final Paint _eyePupil = Paint()..color = Colors.black;
  final Paint _beak = Paint()..color = const Color(0xFFFF7043);
  final Paint _debug = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  GamePainter(this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGround(canvas, size);
    _drawBird(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _sky.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4EC0CA), Color(0xFFB8E8F0)],
    ).createShader(rect);
    canvas.drawRect(rect, _sky);
  }

  void _drawGround(Canvas canvas, Size size) {
    final top = GameConstants.groundTop * size.height;
    canvas.drawRect(
        Rect.fromLTRB(0, top, size.width, size.height), _ground);
    canvas.drawRect(
        Rect.fromLTRB(0, top, size.width, top + size.height * 0.015),
        _grass);
  }

  void _drawBird(Canvas canvas, Size size) {
    final bird = controller.bird;
    final r = controller.birdRadiusPx;
    final center = Offset(size.width * GameConstants.birdX, bird.y * size.height);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(bird.angle);

    // body
    canvas.drawCircle(Offset.zero, r, _body);
    // eye
    canvas.drawCircle(Offset(r * 0.35, -r * 0.30), r * 0.30, _eyeWhite);
    canvas.drawCircle(Offset(r * 0.45, -r * 0.30), r * 0.14, _eyePupil);
    // beak
    final beak = Path()
      ..moveTo(r * 0.7, -r * 0.05)
      ..lineTo(r * 1.4, r * 0.15)
      ..lineTo(r * 0.7, r * 0.40)
      ..close();
    canvas.drawPath(beak, _beak);

    canvas.restore();

    // Debug hitbox (not rotated, like a real AABB)
    if (controller.debug) {
      final hb = r * GameConstants.hitboxShrink;
      canvas.drawRect(
        Rect.fromCenter(center: center, width: hb * 2, height: hb * 2),
        _debug,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => false;
  // Repaints are driven by `repaint: controller`, not by shouldRepaint.
}
