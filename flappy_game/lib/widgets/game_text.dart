import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// White bold text with a soft shadow, readable on any background.
/// [fontSize] is in design pixels and is scaled with ScreenUtil (.sp).
class GameText extends StatelessWidget {
  const GameText(
    this.text, {
    super.key,
    this.fontSize = 18,
    this.color = Colors.white,
  });

  final String text;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize.sp,
        fontWeight: FontWeight.bold,
        color: color,
        decoration: TextDecoration.none,
        shadows: const [
          Shadow(blurRadius: 6, color: Colors.black54, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}
