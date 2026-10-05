import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/difficulty.dart';
import '../models/medal.dart';
import '../models/skin.dart';
import '../utils/settings.dart';
import '../utils/stats.dart';
import '../utils/theme.dart';
import '../widgets/app_button.dart';
import '../widgets/bird_sprite.dart';
import '../widgets/game_text.dart';
import '../widgets/glass_card.dart';
import '../widgets/medal_badge.dart';
import '../widgets/mute_button.dart';
import '../widgets/reveal.dart';
import '../widgets/segmented_pill.dart';
import '../widgets/world_background.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  // One entrance sequence when the app opens: the elements arrive in order.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  void _open(Widget screen) {
    Navigator.of(context).push(AppRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final settings = GameSettings.instance;

    return Scaffold(
      body: WorldBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = min(300.w, constraints.maxWidth * 0.86);

              return Stack(
                children: [
                  SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: SizedBox(
                          width: contentWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Reveal(
                                animation: _intro,
                                end: 0.5,
                                child: ValueListenableBuilder<BirdSkin>(
                                  valueListenable: settings.skin,
                                  builder: (context, skin, _) =>
                                      BirdSprite(size: 112.r, skin: skin),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Reveal(
                                animation: _intro,
                                start: 0.08,
                                end: 0.55,
                                child: Column(
                                  children: [
                                    GameText('Flappy',
                                        fontSize: 60, letterSpacing: 1),
                                    GameText('Game',
                                        fontSize: 26,
                                        color: AppColors.amberLight,
                                        letterSpacing: 8),
                                  ],
                                ),
                              ),
                              SizedBox(height: 26.h),
                              Reveal(
                                animation: _intro,
                                start: 0.2,
                                end: 0.7,
                                child: const _BestCard(),
                              ),
                              SizedBox(height: 14.h),
                              Reveal(
                                animation: _intro,
                                start: 0.3,
                                end: 0.8,
                                child: ValueListenableBuilder<Difficulty>(
                                  valueListenable: settings.difficulty,
                                  builder: (context, current, _) =>
                                      SegmentedPill<Difficulty>(
                                    values: Difficulty.values,
                                    selected: current,
                                    labelOf: (d) => d.label,
                                    onChanged: settings.setDifficulty,
                                  ),
                                ),
                              ),
                              SizedBox(height: 22.h),
                              Reveal(
                                animation: _intro,
                                start: 0.4,
                                end: 0.9,
                                child: AppButton(
                                  label: 'Play',
                                  icon: Icons.play_arrow_rounded,
                                  height: 60,
                                  fontSize: 22,
                                  onPressed: () => _open(const GameScreen()),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Reveal(
                                animation: _intro,
                                start: 0.5,
                                end: 1.0,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AppButton(
                                        label: 'Settings',
                                        icon: Icons.settings_rounded,
                                        style: AppButtonStyle.secondary,
                                        height: 46,
                                        fontSize: 15,
                                        onPressed: () =>
                                            _open(const SettingsScreen()),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: AppButton(
                                        label: 'Stats',
                                        icon: Icons.bar_chart_rounded,
                                        style: AppButtonStyle.secondary,
                                        height: 46,
                                        fontSize: 15,
                                        onPressed: () =>
                                            _open(const StatsScreen()),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Mute toggle (top right)
                  Positioned(
                    top: 8.h,
                    right: 12.w,
                    child: Reveal(
                      animation: _intro,
                      start: 0.5,
                      child: const MuteButton(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Best score for the selected difficulty, with its medal and games played.
/// Updates by itself when a round ends or the difficulty changes.
class _BestCard extends StatelessWidget {
  const _BestCard();

  @override
  Widget build(BuildContext context) {
    final stats = PlayerStats.instance;
    final settings = GameSettings.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([stats.revision, settings.difficulty]),
      builder: (context, _) {
        final d = settings.difficulty.value;
        final best = stats.bestFor(d);

        return GlassCard(
          blur: 10,
          radius: 22,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              MedalBadge(medal: medalForScore(best), size: 46.r),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Best on ${d.label}',
                        style: appStyle(13,
                            color: Colors.white70, weight: FontWeight.w600)),
                    Text('$best',
                        style: appStyle(30, weight: FontWeight.w900, height: 1.1)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${stats.gamesPlayed}',
                      style: appStyle(20, weight: FontWeight.w800)),
                  Text('games',
                      style: appStyle(12,
                          color: Colors.white70, weight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
