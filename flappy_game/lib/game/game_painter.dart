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

  final Paint _pipeFill = Paint()..color = const Color(0xFF73BF2E);
  final Paint _pipeCapFill = Paint()..color = const Color(0xFF5AA01F);
  final Paint _pipeBorder = Paint()
    ..color = const Color(0xFF2E5E0E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  final Paint _debug = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  GamePainter(this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawPipes(canvas, size);
    _drawGround(canvas, size); // ground covers the bottom of the pipes
    _drawBird(canvas, size);
    if (controller.debug) _drawDebug(canvas, size);
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

  // ------------------------------------------------------------------ Pipes

  void _drawPipes(Canvas canvas, Size size) {
    final pw = controller.pipeWidthPx;
    final capH = size.height * GameConstants.pipeCapHeight;

    for (final p in controller.pipes) {
      final top = p.topRect(size, pw);
      final bottom = p.bottomRect(size, pw);

      // Pipe bodies
      canvas.drawRect(top, _pipeFill);
      canvas.drawRect(top, _pipeBorder);
      canvas.drawRect(bottom, _pipeFill);
      canvas.drawRect(bottom, _pipeBorder);

      // Caps (lip at the gap end of each pipe, same width as the hitbox)
      final topCap = Rect.fromLTRB(top.left, top.bottom - capH, top.right, top.bottom);
      final bottomCap =
          Rect.fromLTRB(bottom.left, bottom.top, bottom.right, bottom.top + capH);
      canvas.drawRect(topCap, _pipeCapFill);
      canvas.drawRect(topCap, _pipeBorder);
      canvas.drawRect(bottomCap, _pipeCapFill);
      canvas.drawRect(bottomCap, _pipeBorder);
    }
  }

  // ----------------------------------------------------------------- Ground

  void _drawGround(Canvas canvas, Size size) {
    final top = GameConstants.groundTop * size.height;
    canvas.drawRect(Rect.fromLTRB(0, top, size.width, size.height), _ground);
    canvas.drawRect(
        Rect.fromLTRB(0, top, size.width, top + size.height * 0.015), _grass);
  }

  // ------------------------------------------------------------------- Bird

  void _drawBird(Canvas canvas, Size size) {
    final bird = controller.bird;
    final r = controller.birdRadiusPx;
    final center =
        Offset(size.width * GameConstants.birdX, bird.y * size.height);

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
