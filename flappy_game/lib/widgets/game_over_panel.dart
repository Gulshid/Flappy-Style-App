import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/medal.dart';
import '../utils/theme.dart';
import 'app_button.dart';
import 'game_text.dart';
import 'glass_card.dart';
import 'medal_badge.dart';

/// End-of-round summary. It slides in after a short beat, counts the score up,
/// pops the medal, and shows how far you are from the next medal.
class GameOverPanel extends StatefulWidget {
  const GameOverPanel({
    super.key,
    required this.score,
    required this.best,
    required this.isNewBest,
    required this.difficultyLabel,
    required this.onRestart,
    required this.onMenu,
  });

  final int score;
  final int best;
  final bool isNewBest;
  final String difficultyLabel;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  @override
  State<GameOverPanel> createState() => _GameOverPanelState();
}

class _GameOverPanelState extends State<GameOverPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void initState() {
    super.initState();
    // Short beat so the crash is seen before the panel appears.
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Maps the controller value from [a]..[b] to 0..1.
  double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final medal = medalForScore(widget.score);
    final nextMedal = medal.next;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;

        final enter = Curves.easeOutBack.transform(_seg(t, 0.0, 0.3));
        final fade = Curves.easeOut.transform(_seg(t, 0.0, 0.2));
        final count = Curves.easeOutCubic.transform(_seg(t, 0.2, 0.7));
        final medalPop = Curves.easeOutBack.transform(_seg(t, 0.5, 0.75));
        final bar = Curves.easeOutCubic.transform(_seg(t, 0.3, 0.8));

        final shownScore = (widget.score * count).round();

        // Progress towards the next medal (0..1)
        double progress = 1;
        if (nextMedal != null) {
          final from = medal.threshold;
          final to = nextMedal.threshold;
          progress =
              ((widget.score - from) / (to - from)).clamp(0.0, 1.0).toDouble();
        }

        return Opacity(
          opacity: fade,
          child: Transform.scale(
            scale: 0.85 + 0.15 * enter,
            child: GlassCard(
              width: 300.w,
              radius: 28,
              padding: EdgeInsets.fromLTRB(20.r, 18.r, 20.r, 18.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GameText('Game over', fontSize: 32),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Transform.scale(
                        scale: medalPop.clamp(0.0, 1.3).toDouble(),
                        child: MedalBadge(medal: medal, size: 78.r),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Score',
                                style: appStyle(13,
                                    color: Colors.white70,
                                    weight: FontWeight.w600)),
                            Text('$shownScore',
                                style: appStyle(40,
                                    weight: FontWeight.w900, height: 1.05)),
                            SizedBox(height: 2.h),
                            Text(
                              'Best ${widget.best} on ${widget.difficultyLabel}',
                              style: appStyle(13,
                                  color: Colors.white70,
                                  weight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.isNewBest) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.amberLight, AppColors.amber],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              size: 18.r, color: AppColors.onAmber),
                          SizedBox(width: 4.w),
                          Text('New best score',
                              style: appStyle(13,
                                  color: AppColors.onAmber,
                                  weight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 14.h),
                  _NextMedalBar(
                    progress: progress * bar,
                    text: nextMedal == null
                        ? 'Top medal earned'
                        : '${nextMedal.threshold - widget.score} more for ${nextMedal.label}',
                    color: (nextMedal ?? medal).light,
                  ),
                  SizedBox(height: 16.h),
                  AppButton(
                    label: 'Play again',
                    icon: Icons.replay_rounded,
                    onPressed: widget.onRestart,
                  ),
                  SizedBox(height: 8.h),
                  AppButton(
                    label: 'Menu',
                    icon: Icons.home_rounded,
                    style: AppButtonStyle.secondary,
                    height: 44,
                    fontSize: 16,
                    onPressed: widget.onMenu,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NextMedalBar extends StatelessWidget {
  const _NextMedalBar({
    required this.progress,
    required this.text,
    required this.color,
  });

  final double progress; // 0..1
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: Stack(
            children: [
              Container(
                height: 8.h,
                color: AppColors.alpha(Colors.white, 0.18),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0).toDouble(),
                child: Container(height: 8.h, color: color),
              ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        Text(text,
            style: appStyle(13,
                color: Colors.white70, weight: FontWeight.w600)),
      ],
    );
  }
}
