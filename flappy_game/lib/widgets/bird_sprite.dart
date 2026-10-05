import 'dart:math';

import 'package:flutter/material.dart';

import '../game/game_assets.dart';
import '../models/skin.dart';
import '../utils/constants.dart';

/// The real bird sprite, animated (flapping wings and a gentle hover).
/// Used on the menu and in the skin picker. [size] is the sprite width in
/// real pixels (pass e.g. `110.r`).
class BirdSprite extends StatefulWidget {
  const BirdSprite({
    super.key,
    required this.size,
    this.skin = BirdSkin.classic,
    this.animate = true,
  });

  final double size;
  final BirdSkin skin;

  /// false = a still picture (cheaper; good for lists).
  final bool animate;

  @override
  State<BirdSprite> createState() => _BirdSpriteState();
}

class _BirdSpriteState extends State<BirdSprite>
    with SingleTickerProviderStateMixin {
  // One loop = 2.4 s: 24 wing steps (10 per second) and one hover cycle.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size * 0.8 + (widget.animate ? widget.size * 0.14 : 0),
        child: CustomPaint(
          painter: _BirdSpritePainter(
            _controller,
            GameAssets.instance,
            widget.skin,
            widget.animate,
          ),
        ),
      ),
    );
  }
}

class _BirdSpritePainter extends CustomPainter {
  _BirdSpritePainter(this.animation, this.assets, this.skin, this.animate)
      : super(repaint: animation) {
    _paint.colorFilter = skin.filter;
  }

  final Animation<double> animation;
  final GameAssets assets;
  final BirdSkin skin;
  final bool animate;
  final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    final seq = GameConstants.wingSequence;
    final step = animate ? (animation.value * 24).floor() % seq.length : 1;
    final frame = assets.birdFrames[animate ? seq[step] : 1];

    final w = size.width;
    final h = w * frame.height / frame.width;
    final bob = animate ? sin(animation.value * 2 * pi) * size.width * 0.06 : 0.0;

    final src =
        Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble());
    canvas.drawImageRect(
      frame,
      src,
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 + bob),
        width: w,
        height: h,
      ),
      _paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BirdSpritePainter old) => old.skin != skin;
}
