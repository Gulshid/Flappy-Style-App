import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../game/game_assets.dart';
import '../game/game_controller.dart';
import '../game/game_painter.dart';
import '../models/game_state.dart';
import '../utils/audio.dart';
import '../utils/constants.dart';
import '../utils/settings.dart';
import '../utils/storage.dart';
import '../widgets/game_over_panel.dart';
import '../widgets/game_text.dart';
import '../widgets/mute_button.dart';
import '../widgets/pause_panel.dart';
import '../widgets/score_display.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // The controller only ANNOUNCES things (new best, flap, crash...). This
  // screen decides what to do about them, so the game logic stays free of
  // storage / audio code and is easy to test.
  late final GameController controller = GameController(
    difficulty: GameSettings.instance.difficulty.value,
    onNewBest: Storage.saveBest,
    onEvent: _handleEvent,
  );

  late final Ticker _ticker;
  late final GamePainter _painter;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Images were preloaded in main(), so there is no loading flicker
    _painter = GamePainter(controller, GameAssets.instance);

    // Load the saved high score at startup
    Storage.loadBest().then((best) {
      if (mounted) controller.setBestScore(best);
    });

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

  // ------------------------------------------------------ Sound + haptics

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

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4EC0CA), // sky colour beside the game
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

        // Mute + debug toggles (top left)
        Positioned(
          top: topInset,
          left: 8.w,
          child: Row(
            children: [
              const MuteButton(),
              // Debug toggle (hitboxes) — remove later
              IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.white),
                onPressed: controller.toggleDebug,
              ),
            ],
          ),
        ),

        // 3-2-1 countdown after Resume
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder<int>(
              valueListenable: controller.countdownNotifier,
              builder: (context, n, _) => n > 0
                  ? Center(child: GameText('$n', fontSize: 96))
                  : const SizedBox.shrink(),
            ),
          ),
        ),

        // Pause menu (dims the game and blocks taps behind it)
        Positioned.fill(
          child: ValueListenableBuilder<bool>(
            valueListenable: controller.pausedNotifier,
            builder: (context, paused, _) {
              if (!paused) return const SizedBox.shrink();
              return Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: PausePanel(
                  onResume: controller.resume,
                  onMenu: () => Navigator.of(context).pop(),
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
        // First launch only: a short hint on how to play
        final showTutorial = !GameSettings.instance.tutorialSeen;
        return IgnorePointer(
          child: Align(
            alignment: const Alignment(0, -0.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GameText('Get Ready', fontSize: 36),
                SizedBox(height: 8.h),
                const GameText('Tap to start', fontSize: 20),
                if (showTutorial) ...[
                  SizedBox(height: 24.h),
                  Icon(
                    Icons.touch_app,
                    size: 48.r,
                    color: Colors.white,
                    shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
                  ),
                  SizedBox(height: 8.h),
                  const GameText('Tap to flap.\nFly through the gaps!',
                      fontSize: 18),
                ],
              ],
            ),
          ),
        );

      case GameState.playing:
        return Stack(
          children: [
            IgnorePointer(
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 24.h),
                    child: ScoreDisplay(score: controller.scoreNotifier),
                  ),
                ),
              ),
            ),
            // Pause button (top right)
            Positioned(
              top: topInset,
              right: 8.w,
              child: IconButton(
                onPressed: controller.pause,
                icon: Icon(
                  Icons.pause_rounded,
                  color: Colors.white,
                  size: 32.r,
                  shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
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
            onRestart: controller.reset,
            onMenu: () => Navigator.of(context).pop(),
          ),
        );
    }
  }
}
