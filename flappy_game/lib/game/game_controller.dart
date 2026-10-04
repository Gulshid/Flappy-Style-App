import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/bird.dart';
import '../models/pipe.dart';
import '../utils/constants.dart';

/// Owns all game state and rules. Knows nothing about widgets or painting.
/// It is a [ChangeNotifier] so the painter can repaint without rebuilding
/// the widget tree every frame.
class GameController extends ChangeNotifier {
  /// [rng] can be injected in tests (Phase 10) for predictable pipes.
  GameController({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  final Bird bird = Bird();
  final List<Pipe> pipes = [];

  /// TEMPORARY (Phase 4): simple game-over flag. Phase 6 replaces this with
  /// a proper GameState enum (ready / playing / gameOver).
  final ValueNotifier<bool> gameOverNotifier = ValueNotifier<bool>(false);
  bool get isGameOver => gameOverNotifier.value;

  // Layout (pixels), set by the screen's LayoutBuilder
  Size viewSize = Size.zero;
  double birdRadiusPx = 0;
  double pipeWidthPx = 0;

  bool debug = GameConstants.debugHitboxes;

  // Pipe spawning
  double _spawnTimer = GameConstants.pipeSpawnInterval; // spawn one right away
  double? _lastGapY;

  // Time since death (so an accidental tap doesn't restart instantly)
  double _deadTime = 0;

  // ---------------------------------------------------------------- Layout

  /// Called by the screen's LayoutBuilder whenever the layout changes.
  /// [birdRadiusPx] and [pipeWidthPx] are already scaled with ScreenUtil.
  void updateLayout(Size size, double birdRadiusPx, double pipeWidthPx) {
    viewSize = size;
    this.birdRadiusPx = birdRadiusPx;
    this.pipeWidthPx = pipeWidthPx;
  }

  double get _birdRadiusNorm =>
      viewSize.height == 0 ? 0 : birdRadiusPx / viewSize.height;

  double get _pipeHalfWidthNorm =>
      viewSize.width == 0 ? 0 : (pipeWidthPx / 2) / viewSize.width;

  // ---------------------------------------------------------------- Hitbox

  /// Bird hitbox in pixel space, slightly smaller than the drawn bird.
  Rect get birdRect {
    final half = birdRadiusPx * GameConstants.hitboxShrink;
    final center = Offset(
      viewSize.width * GameConstants.birdX,
      bird.y * viewSize.height,
    );
    return Rect.fromCenter(center: center, width: half * 2, height: half * 2);
  }

  // ---------------------------------------------------------------- Update

  void update(double dt) {
    if (viewSize.isEmpty) return;

    if (isGameOver) {
      _updateDead(dt);
    } else {
      bird.update(dt);
      _updatePipes(dt);
      _checkCollisions();
    }

    notifyListeners(); // repaint
  }

  // After death: pipes freeze, the bird just falls to the ground.
  void _updateDead(double dt) {
    _deadTime += dt;
    bird.update(dt);
    _clampBirdToWorld();
  }

  void _clampBirdToWorld() {
    bird.clampTo(
      top: _birdRadiusNorm,
      bottom: GameConstants.groundTop - _birdRadiusNorm,
    );
  }

  // ----------------------------------------------------------------- Pipes

  void _updatePipes(double dt) {
    _spawnTimer += dt;
    if (_spawnTimer >= GameConstants.pipeSpawnInterval) {
      _spawnTimer -= GameConstants.pipeSpawnInterval;
      _spawnPipe();
    }

    final dx = GameConstants.pipeSpeed * dt;
    for (final p in pipes) {
      p.x -= dx;
    }

    // Safe removal: pipe is completely off the left edge
    final halfW = _pipeHalfWidthNorm;
    pipes.removeWhere((p) => p.x < -halfW);
  }

  void _spawnPipe() {
    const gap = GameConstants.pipeGapSize;
    const margin = GameConstants.pipeGapMargin;

    // Gap centre limits so the gap never touches ceiling/ground margins
    var minY = margin + gap / 2;
    var maxY = GameConstants.groundTop - margin - gap / 2;

    // Keep consecutive gaps reachable: limit how far the gap can jump
    final last = _lastGapY;
    if (last != null) {
      minY = max(minY, last - GameConstants.pipeMaxGapShift);
      maxY = min(maxY, last + GameConstants.pipeMaxGapShift);
    }

    final gapY = minY + _rng.nextDouble() * (maxY - minY);
    _lastGapY = gapY;

    pipes.add(Pipe(
      x: 1.0 + _pipeHalfWidthNorm, // just outside the right edge
      gapCenterY: gapY,
      gapSize: gap,
    ));
  }

  // ------------------------------------------------------------- Collision

  void _checkCollisions() {
    final rect = birdRect;

    // Ground
    if (rect.bottom >= GameConstants.groundTop * viewSize.height) {
      _die();
      return;
    }

    // Ceiling
    if (rect.top <= 0) {
      if (GameConstants.ceilingKills) {
        _die();
        return;
      }
      bird.clampTo(top: _birdRadiusNorm, bottom: double.infinity);
    }

    // Pipes
    if (_hitsAnyPipe(rect)) _die();
  }

  /// AABB check: bird rect vs the top and bottom rect of every pipe.
  bool _hitsAnyPipe(Rect birdRect) {
    for (final p in pipes) {
      if (birdRect.overlaps(p.topRect(viewSize, pipeWidthPx)) ||
          birdRect.overlaps(p.bottomRect(viewSize, pipeWidthPx))) {
        return true;
      }
    }
    return false;
  }

  void _die() {
    _deadTime = 0;
    _clampBirdToWorld();
    gameOverNotifier.value = true;
  }

  // ----------------------------------------------------------------- Input

  void onTap() {
    if (isGameOver) {
      if (_deadTime >= GameConstants.restartDelay) reset();
      return;
    }
    bird.flap();
  }

  void toggleDebug() {
    debug = !debug;
    notifyListeners();
  }

  void reset() {
    bird.reset();
    pipes.clear();
    _spawnTimer = GameConstants.pipeSpawnInterval;
    _lastGapY = null;
    _deadTime = 0;
    gameOverNotifier.value = false;
    notifyListeners();
  }

  @override
  void dispose() {
    gameOverNotifier.dispose();
    super.dispose();
  }
}
