import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/theme.dart';
import 'game_text.dart';

/// Big score at the top of the screen. The number pops each time it changes,
/// and a small chip shows the best score (or "New best" once you beat it).
/// Only this widget rebuilds when the score changes.
class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({super.key, required this.score, required this.best});

  final ValueListenable<int> score;

  /// The best score from before this round.
  final int best;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: score,
      builder: (context, value, _) {
        final beating = best > 0 && value > best;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A new key restarts the pop animation on every point.
            TweenAnimationBuilder<double>(
              key: ValueKey(value),
              tween: Tween<double>(begin: 1.35, end: 1.0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: GameText('$value', fontSize: 56),
            ),
            if (best > 0) ...[
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: beating
                      ? AppColors.amber
                      : AppColors.alpha(AppColors.ink, 0.42),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  beating ? 'New best' : 'Best $best',
                  style: appStyle(
                    13,
                    weight: FontWeight.w800,
                    color: beating ? AppColors.onAmber : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
