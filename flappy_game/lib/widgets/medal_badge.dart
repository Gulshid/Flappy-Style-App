import 'package:flutter/material.dart';

import '../models/medal.dart';
import '../utils/theme.dart';

/// Round medal. Dimmed outline when [medal] is [Medal.none].
/// [size] is in real pixels (pass e.g. `48.r`).
class MedalBadge extends StatelessWidget {
  const MedalBadge({super.key, required this.medal, required this.size});

  final Medal medal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final earned = medal != Medal.none;

    return Semantics(
      label: medal.label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: earned ? null : AppColors.alpha(Colors.white, 0.10),
          gradient: earned
              ? RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: [medal.light, medal.dark],
                )
              : null,
          border: Border.all(
            color: AppColors.alpha(Colors.white, earned ? 0.85 : 0.25),
            width: size * 0.05,
          ),
          boxShadow: earned
              ? [
                  BoxShadow(
                    color: AppColors.alpha(medal.dark, 0.55),
                    blurRadius: size * 0.3,
                    offset: Offset(0, size * 0.08),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.military_tech_rounded,
          size: size * 0.58,
          color: earned ? Colors.white : AppColors.alpha(Colors.white, 0.35),
        ),
      ),
    );
  }
}
