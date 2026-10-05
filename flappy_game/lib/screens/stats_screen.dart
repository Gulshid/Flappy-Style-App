import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/difficulty.dart';
import '../models/medal.dart';
import '../utils/stats.dart';
import '../utils/theme.dart';
import '../widgets/game_text.dart';
import '../widgets/glass_card.dart';
import '../widgets/medal_badge.dart';
import '../widgets/screen_frame.dart';

/// Lifetime statistics and the best score on each difficulty.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = PlayerStats.instance;

    return ScreenFrame(
      title: 'Statistics',
      child: AnimatedBuilder(
        animation: stats.revision,
        builder: (context, _) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.sports_esports_rounded,
                      value: '${stats.gamesPlayed}',
                      label: 'Games played',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.flag_rounded,
                      value: '${stats.totalScore}',
                      label: 'Pipes cleared',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.trending_up_rounded,
                      value: stats.averageScore.toStringAsFixed(1),
                      label: 'Average score',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.emoji_events_rounded,
                      value: '${stats.overallBest}',
                      label: 'Best score',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 22.h),
              const Align(
                alignment: Alignment.centerLeft,
                child: GameText('Best by difficulty', fontSize: 18),
              ),
              SizedBox(height: 10.h),
              GlassCard(
                blur: 10,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                child: Column(
                  children: [
                    for (final d in Difficulty.values)
                      _DifficultyRow(
                        difficulty: d,
                        best: stats.bestFor(d),
                        showDivider: d != Difficulty.values.last,
                      ),
                  ],
                ),
              ),
              SizedBox(height: 22.h),
              const _MedalGuide(),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 10,
      radius: 20,
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.amberLight, size: 22.r),
          SizedBox(height: 10.h),
          Text(value, style: appStyle(28, weight: FontWeight.w900, height: 1.1)),
          SizedBox(height: 2.h),
          Text(label,
              style: appStyle(13, color: Colors.white70, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({
    required this.difficulty,
    required this.best,
    required this.showDivider,
  });

  final Difficulty difficulty;
  final int best;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            children: [
              MedalBadge(medal: medalForScore(best), size: 40.r),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(difficulty.label,
                    style: appStyle(17, weight: FontWeight.w800)),
              ),
              Text('$best', style: appStyle(22, weight: FontWeight.w900)),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: AppColors.alpha(Colors.white, 0.14)),
      ],
    );
  }
}

/// Shows which score earns which medal.
class _MedalGuide extends StatelessWidget {
  const _MedalGuide();

  @override
  Widget build(BuildContext context) {
    const medals = [Medal.bronze, Medal.silver, Medal.gold, Medal.platinum];

    return GlassCard(
      blur: 10,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final m in medals)
            Column(
              children: [
                MedalBadge(medal: m, size: 40.r),
                SizedBox(height: 6.h),
                Text('${m.threshold}+',
                    style: appStyle(14, weight: FontWeight.w800)),
              ],
            ),
        ],
      ),
    );
  }
}
