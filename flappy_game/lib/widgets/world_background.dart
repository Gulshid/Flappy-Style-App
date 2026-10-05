import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/game_assets.dart';
import '../game/layers.dart';
import '../game/sky_palette.dart';
import '../game/sky_renderer.dart';
import '../utils/constants.dart';

/// Shared clock for the menu backgrounds. It is one object for the whole app,
/// so the sky keeps its place when you move between Menu, Settings and Stats
/// instead of jumping back to daytime.
class _WorldClock extends ChangeNotifier {
  static final _WorldClock shared = _WorldClock();

  double time = 0;
  double scroll = 0;
  SkyPalette sky = SkyPalette.day;

  /// Seconds each sky stage lasts on the menus.
  static const double _stageSeconds = 9;

  void tick(double dt) {
    time += dt;
    scroll += 0.2 * dt; // screen widths per second (ground speed)
    final stage =
        (time / _stageSeconds).floor() % SkyPalette.stages.length;
    sky = SkyPalette.lerp(
        sky, SkyPalette.stages[stage], 1 - exp(-1.3 * dt));
    notifyListeners();
  }
}

/// The animated world behind the menu screens: parallax clouds, hills and
/// ground under a sky that drifts through day, sunset, night and dawn.
/// Put the screen content in [child].
class WorldBackground extends StatefulWidget {
  const WorldBackground({super.key, this.child});

  final Widget? child;

  @override
  State<WorldBackground> createState() => _WorldBackgroundState();
}

class _WorldBackgroundState extends State<WorldBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final _WorldPainter _painter =
      _WorldPainter(_WorldClock.shared, GameAssets.instance);
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      var dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      if (dt > GameConstants.maxDt) dt = GameConstants.maxDt;
      _WorldClock.shared.tick(dt);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(child: CustomPaint(painter: _painter)),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _WorldPainter extends CustomPainter {
  _WorldPainter(this.clock, this.assets) : super(repaint: clock);

  final _WorldClock clock;
  final GameAssets assets;
  final SkyRenderer _sky = SkyRenderer();

  @override
  void paint(Canvas canvas, Size size) {
    _sky.paint(canvas, size, clock.sky, clock.time);
    final layer = _sky.layer;

    drawTiledLayer(
      canvas,
      size,
      assets.clouds,
      layer,
      top: size.height * GameConstants.cloudsTop,
      height: size.height * GameConstants.cloudsHeight,
      offset: clock.scroll * GameConstants.cloudsParallax * size.width,
    );
    drawTiledLayer(
      canvas,
      size,
      assets.hills,
      layer,
      top: size.height * GameConstants.groundTop -
          size.height * GameConstants.hillsHeight,
      height: size.height * GameConstants.hillsHeight,
      offset: clock.scroll * GameConstants.hillsParallax * size.width,
    );
    drawTiledLayer(
      canvas,
      size,
      assets.ground,
      layer,
      top: size.height * GameConstants.groundTop,
      height: size.height * GameConstants.groundHeight,
      offset: clock.scroll * GameConstants.groundParallax * size.width,
    );
  }

  @override
  bool shouldRepaint(covariant _WorldPainter oldDelegate) => false;
}
