import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../game/game_assets.dart';
import '../game/game_controller.dart';
import '../game/game_painter.dart';
import '../models/difficulty.dart';
import '../models/game_state.dart';
import '../utils/audio.dart';
import '../utils/constants.dart';
import '../utils/settings.dart';
import '../utils/stats.dart';
import '../utils/theme.dart';
import '../widgets/game_over_panel.dart';
import '../widgets/game_text.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/mute_button.dart';
import '../widgets/pause_panel.dart';
import '../widgets/reveal.dart';
import '../widgets/score_display.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // The difficulty is fixed for the whole screen's life (it can only be
  // changed from the menu / settings).
  final _difficulty = GameSettings.instance.difficulty.value;

  // The controller only ANNOUNCES things (round ended, flap, crash...). This
  // screen decides what to do about them, so the game logic stays free of
  // storage / audio code and is easy to test.
  late final GameController controller = GameController(
    difficulty: _difficulty,
    dynamicSky: GameSettings.instance.dynamicSky.value,
    onRoundEnd: _onRoundEnd,
    onEvent: _handleEvent,
  );

  late final Ticker _ticker;
  late final GamePainter _painter;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Images were preloaded in main(), so there is no loading flicker
    _painter = GamePainter(
      controller,
      GameAssets.instance,
      skin: GameSettings.instance.skin.value,
    );

    // The best score for this difficulty is already in memory
    controller.setBestScore(PlayerStats.instance.bestFor(_difficulty));
    controller.debug = GameSettings.instance.showHitboxes.value;

    _ticker = createTicker((elapsed) {
      // Delta time in seconds -> frame-rate independent movement
      var dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      if (dt > GameConstants.maxDt) dt = GameConstants.maxDt;
      controller.update(dt); // notifies painter, no setState needed
    })..start();

    // Pause when the app goes to the background / a call comes in
    WidgetsBinding.instance.addObserver(this);

    controller.pausedNotifier.addListener(_onPausedChanged);
    controller.stateNotifier.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.pausedNotifier.removeListener(_onPausedChanged);
    controller.stateNotifier.removeListener(_onStateChanged);
    _ticker.dispose();
    controller.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ Lifecycle

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Anything other than "resumed" (inactive, paused, hidden...) means the
    // player can't see the game. pause() does nothing unless a round is
    // running, so this is always safe.
    if (state != AppLifecycleState.resumed) controller.pause();
  }

  /// While paused the ticker is muted: no frames are processed, which also
  /// saves battery. The first frame after resuming gets a large dt, which
  /// maxDt caps, so nothing jumps.
  void _onPausedChanged() {
    _ticker.muted = controller.isPaused;
  }

  /// The first time a round starts, remember it so the tutorial hint is not
  /// shown again.
  void _onStateChanged() {
    if (controller.state == GameState.playing) {
      unawaited(GameSettings.instance.markTutorialSeen());
    }
  }

  // --------------------------------------------------- Stats, sound, haptics

  void _onRoundEnd(int score) {
    unawaited(PlayerStats.instance.recordRound(score, _difficulty));
  }

  void _handleEvent(GameEvent event) {
    final audio = GameAudio.instance;
    switch (event) {
      case GameEvent.flap:
        unawaited(audio.play(Sfx.flap));
      case GameEvent.score:
        unawaited(audio.play(Sfx.score));
      case GameEvent.hit:
        unawaited(audio.play(Sfx.hit));
        if (GameSettings.instance.vibration.value) {
          unawaited(HapticFeedback.heavyImpact()); // short vibration on death
        }
      case GameEvent.gameOver:
        unawaited(audio.play(Sfx.gameOver));
    }
  }

  void _quitToMenu() => Navigator.of(context).pop();

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyTop, // sky colour beside the game
      body: LayoutBuilder(
        builder: (context, constraints) {
          // The play area is never wider than maxPlayAspect * height. On
          // phones and portrait tablets this changes nothing; on very wide
          // screens (foldables, landscape, desktop) the game stays centred
          // instead of stretching.
          final playWidth = min(
            constraints.maxWidth,
            constraints.maxHeight * GameConstants.maxPlayAspect,
          );
          final playSize = Size(playWidth, constraints.maxHeight);

          // Give the controller the real play-area size plus ScreenUtil
          // scaled sizes so the bird and pipes look the same on every device.
          controller.updateLayout(
            playSize,
            GameConstants.birdRadiusDesign.r,
            GameConstants.pipeWidthDesign.w,
          );

          return Center(
            child: SizedBox.fromSize(
              size: playSize,
              child: ClipRect(child: _buildPlayArea(context)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayArea(BuildContext context) {
    // Keeps buttons clear of notches / status bar
    final topInset = MediaQuery.of(context).padding.top + 8.h;

    return Stack(
      children: [
        // Game canvas + tap input (only the canvas listens for taps, so the
        // overlay buttons are never affected by it)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => controller.onTap(), // lower lag than onTap
            child: RepaintBoundary(
              child: CustomPaint(painter: _painter),
            ),
          ),
        ),

        // Overlay that changes with the game state
        Positioned.fill(
          child: ValueListenableBuilder<GameState>(
            valueListenable: controller.stateNotifier,
            builder: (context, state, _) => _buildStateOverlay(state, topInset),
          ),
        ),

        // Mute (top left)
        Positioned(
          top: topInset,
          left: 12.w,
          child: const MuteButton(),
        ),

        // 3-2-1 countdown after Resume
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder<int>(
              valueListenable: controller.countdownNotifier,
              builder: (context, n, _) {
                if (n <= 0) return const SizedBox.shrink();
                // New key per number -> the pop animation restarts
                return Center(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(n),
                    tween: Tween<double>(begin: 1.6, end: 1.0),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: GameText('$n', fontSize: 110),
                  ),
                );
              },
            ),
          ),
        ),

        // Pause menu (dims + blurs the frozen game, blocks taps behind it)
        Positioned.fill(
          child: ValueListenableBuilder<bool>(
            valueListenable: controller.pausedNotifier,
            builder: (context, paused, _) {
              if (!paused) return const SizedBox.shrink();
              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: AppColors.alpha(AppColors.ink, 0.45),
                  alignment: Alignment.center,
                  child: PausePanel(
                    onResume: controller.resume,
                    onRestart: controller.reset,
                    onMenu: _quitToMenu,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStateOverlay(GameState state, double topInset) {
    switch (state) {
      case GameState.ready:
        return _buildReadyOverlay();

      case GameState.playing:
        return Stack(
          children: [
            IgnorePointer(
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 18.h),
                    child: ScoreDisplay(
                      score: controller.scoreNotifier,
                      best: controller.bestScore,
                    ),
                  ),
                ),
              ),
            ),
            // Pause button (top right)
            Positioned(
              top: topInset,
              right: 12.w,
              child: GlassIconButton(
                icon: Icons.pause_rounded,
                tooltip: 'Pause',
                onPressed: controller.pause,
              ),
            ),
          ],
        );

      case GameState.gameOver:
        return Center(
          child: GameOverPanel(
            score: controller.score,
            best: controller.bestScore,
            isNewBest: controller.isNewBest,
            difficultyLabel: _difficulty.label,
            onRestart: controller.reset,
            onMenu: _quitToMenu,
          ),
        );
    }
  }

  Widget _buildReadyOverlay() {
    // First launch only: a short card on how to play
    final showTutorial = !GameSettings.instance.tutorialSeen;

    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.55),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GameText('Get ready', fontSize: 40),
            SizedBox(height: 10.h),
            Pulse(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.alpha(AppColors.ink, 0.5),
                  borderRadius: BorderRadius.circular(30.r),
                  border:
                      Border.all(color: AppColors.alpha(Colors.white, 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded,
                        color: Colors.white, size: 22.r),
                    SizedBox(width: 8.w),
                    Text('Tap to start',
                        style: appStyle(16, weight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            if (showTutorial) ...[
              SizedBox(height: 22.h),
              GlassCard(
                blur: 0,
                radius: 20,
                padding:
                    EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tip(Icons.touch_app_rounded, 'Tap to flap'),
                    SizedBox(height: 8.h),
                    _tip(Icons.swap_vert_rounded, 'Fly through the gaps'),
                    SizedBox(height: 8.h),
                    _tip(Icons.warning_amber_rounded, 'Avoid pipes and the ground'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.amberLight, size: 20.r),
          SizedBox(width: 10.w),
          Text(text, style: appStyle(14, weight: FontWeight.w700)),
        ],
      );
}
