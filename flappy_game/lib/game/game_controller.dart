import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../models/bird.dart';
import '../utils/constants.dart';

/// Owns all game state and rules. Knows nothing about widgets or painting.
/// It is a [ChangeNotifier] so the painter can repaint without rebuilding
/// the widget tree every frame.
class GameController extends ChangeNotifier {
  final Bird bird = Bird();

  Size viewSize = Size.zero;
  double birdRadiusPx = 0;

  bool debug = GameConstants.debugHitboxes;

  /// Called by the screen's LayoutBuilder whenever the layout changes.
  /// [birdRadiusPx] is already scaled with ScreenUtil (.r).
  void updateLayout(Size size, double birdRadiusPx) {
    viewSize = size;
    this.birdRadiusPx = birdRadiusPx;
  }

  /// Bird radius expressed in screen heights (for the normalized physics).
  double get _birdRadiusNorm =>
      viewSize.height == 0 ? 0 : birdRadiusPx / viewSize.height;

  void update(double dt) {
    if (viewSize.isEmpty) return;

    bird.update(dt);
    bird.clampTo(
      top: _birdRadiusNorm,
      bottom: GameConstants.groundTop - _birdRadiusNorm,
    );

    notifyListeners(); // repaint
  }

  void onTap() => bird.flap();

  void toggleDebug() {
    debug = !debug;
    notifyListeners();
  }

  void reset() {
    bird.reset();
    notifyListeners();
  }
}
