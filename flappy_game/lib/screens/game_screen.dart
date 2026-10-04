import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../game/game_controller.dart';
import '../game/game_painter.dart';
import '../utils/constants.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final GameController controller = GameController();
  late final Ticker _ticker;
  late final GamePainter _painter;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _painter = GamePainter(controller);

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

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => controller.onTap(), // lower lag than onTap
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: _painter),
                  ),
                ),

                // TEMPORARY game-over text (Phase 6 replaces this with a
                // real Game Over panel + Restart button)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: controller.gameOverNotifier,
                      builder: (context, isOver, _) {
                        if (!isOver) return const SizedBox.shrink();
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Game Over',
                                style: TextStyle(
                                  fontSize: 40.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  decoration: TextDecoration.none,
                                  shadows: const [
                                    Shadow(blurRadius: 6, color: Colors.black54),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Tap to restart',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  color: Colors.white,
                                  decoration: TextDecoration.none,
                                  shadows: const [
                                    Shadow(blurRadius: 6, color: Colors.black54),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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
            ),
          );
        },
      ),
    );
  }
}
