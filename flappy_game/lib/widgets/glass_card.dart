import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/theme.dart';

/// Dark translucent panel with a thin light edge. Used for every card, panel
/// and tile so the whole app shares one surface style.
///
/// [blur] frosts whatever is behind it. Keep it at 0 over the live game
/// canvas (a blur there would be recomputed every frame).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.padding,
    this.radius = 24,
    this.blur = 12,
  });

  final Widget child;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius.r);

    Widget card = Container(
      width: width,
      padding: padding ?? EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.alpha(AppColors.ink, 0.55),
            AppColors.alpha(AppColors.ink, 0.38),
          ],
        ),
        border: Border.all(
          color: AppColors.alpha(Colors.white, 0.22),
          width: 1.2,
        ),
      ),
      child: child,
    );

    if (blur > 0) {
      card = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: card,
        ),
      );
    }
    return card;
  }
}
