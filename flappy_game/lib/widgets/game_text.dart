import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/theme.dart';

/// Chunky white text with a dark outline and soft shadow. Readable on any
/// background, including the night sky. [fontSize] is in design pixels and
/// is scaled with ScreenUtil (.sp).
class GameText extends StatelessWidget {
  const GameText(
    this.text, {
    super.key,
    this.fontSize = 18,
    this.color = Colors.white,
    this.letterSpacing = 0,
    this.outline = true,
  });

  final String text;
  final double fontSize;
  final Color color;
  final double letterSpacing;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    final size = fontSize.sp;
    final base = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      letterSpacing: letterSpacing,
      height: 1.1,
      decoration: TextDecoration.none,
    );

    final fill = Text(
      text,
      textAlign: TextAlign.center,
      style: base.copyWith(color: color),
    );

    if (!outline) return fill;

    final stroke = Text(
      text,
      textAlign: TextAlign.center,
      style: base.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.16
          ..strokeJoin = StrokeJoin.round
          ..color = AppColors.alpha(AppColors.ink, 0.9),
        shadows: [
          Shadow(
            blurRadius: 8,
            color: AppColors.alpha(Colors.black, 0.4),
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );

    return Stack(
      alignment: Alignment.center,
      children: [ExcludeSemantics(child: stroke), fill],
    );
  }
}
