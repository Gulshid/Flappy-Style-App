import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../game/game_controller.dart';
import '../game/game_painter.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../utils/storage.dart';
import '../widgets/game_over_panel.dart';
import '../widgets/game_text.dart';
import '../widgets/score_display.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  // The controller saves a new best score through Storage, but never
  // touches shared_preferences itself (keeps the logic easy to test).
  final GameController controller = GameController(onNewBest: Storage.saveBest);

  late final Ticker _ticker;
  late final GamePainter _painter;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _painter = GamePainter(controller);

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
  }

  @override
  void dispose() {
    _ticker.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Give the controller the real play-area size plus ScreenUtil
          // scaled sizes so the bird and pipes look the same on every device.
          controller.updateLayout(
            constraints.biggest,
            GameConstants.birdRadiusDesign.r,
            GameConstants.pipeWidthDesign.w,
          );

          return Stack(
            children: [
              // Game canvas + tap input (only the canvas listens for taps,
              // so the overlay buttons are never affected by it)
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
                  builder: (context, state, _) => _buildOverlay(state),
                ),
              ),

              // Debug toggle (hitboxes) — remove later
              Positioned(
                top: MediaQuery.of(context).padding.top + 8.h,
                right: 8.w,
                child: IconButton(
                  icon: const Icon(Icons.bug_report, color: Colors.white),
                  onPressed: controller.toggleDebug,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverlay(GameState state) {
    switch (state) {
      case GameState.ready:
        return const IgnorePointer(
          child: Align(
            alignment: Alignment(0, -0.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameText('Get Ready', fontSize: 36),
                SizedBox(height: 8),
                GameText('Tap to start', fontSize: 20),
              ],
            ),
          ),
        );

      case GameState.playing:
        return IgnorePointer(
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 24.h),
                child: ScoreDisplay(score: controller.scoreNotifier),
              ),
            ),
          ),
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
