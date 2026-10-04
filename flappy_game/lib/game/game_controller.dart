import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/bird.dart';
import '../models/difficulty.dart';
import '../models/game_state.dart';
import '../models/pipe.dart';
import '../utils/constants.dart';

/// Owns all game state and rules. Knows nothing about widgets, painting,
/// storage or audio. It is a [ChangeNotifier] so the painter can repaint
/// without rebuilding the widget tree every frame.
class GameController extends ChangeNotifier {
  /// [difficulty] decides the pipe speed and gap size curve.
  /// [rng] can be injected in tests (Phase 10) for predictable pipes.
  /// [onNewBest] is called when a round ends with a new high score.
  /// [onEvent] is called for flap / score / hit / gameOver so the screen can
  /// play sounds and vibrate.
  GameController({
    this.difficulty = Difficulty.normal,
    Random? rng,
    this.onNewBest,
    this.onEvent,
  }) : _rng = rng ?? Random();

  final Difficulty difficulty;
  final Random _rng;
  final Future<void> Function(int score)? onNewBest;
  final void Function(GameEvent event)? onEvent;

  final Bird bird = Bird();
  final List<Pipe> pipes = [];

  // ----------------------------------------------------------------- State
  final ValueNotifier<GameState> stateNotifier =
      ValueNotifier<GameState>(GameState.ready);
  GameState get state => stateNotifier.value;

  // ----------------------------------------------------------------- Score
  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  int get score => scoreNotifier.value;

  int bestScore = 0;
  bool isNewBest = false;

  /// Called after the saved high score has been loaded from storage.
  void setBestScore(int value) {
    if (value > bestScore) bestScore = value;
  }

  // ------------------------------------------------- Difficulty (Phase 9)
  /// Current pipe speed (screen widths / second): grows with the score.
  double get pipeSpeed => difficulty.pipeSpeed(score);

  /// Current gap size (screen heights): shrinks with the score.
  double get gapSize => difficulty.gapSize(score);

  // ------------------------------------------------------ Pause (Phase 9)
  /// True while the pause menu is open.
  final ValueNotifier<bool> pausedNotifier = ValueNotifier<bool>(false);
  bool get isPaused => pausedNotifier.value;

  /// 3, 2, 1 after pressing Resume; 0 when there is no countdown.
  final ValueNotifier<int> countdownNotifier = ValueNotifier<int>(0);
  double _countdown = 0;

  // -------------------------------------------------------- Visual state
  /// How far the world has scrolled, in screen widths. The painter turns
  /// this into pixel offsets for the ground and the parallax layers.
  double scroll = 0;

  /// Seconds of animation time (drives the wing flapping). Frozen on death.
  double animTime = 0;

  /// Screen shake strength: 1.0 right after a crash, fading to 0.
  double shake = 0;

  // ---------------------------------------------------- Layout (pixels)
  Size viewSize = Size.zero;
  double birdRadiusPx = 0;
  double pipeWidthPx = 0;

  bool debug = GameConstants.debugHitboxes;

  // ---------------------------------------------------- Internal timers
  // Distance (screen widths) travelled since the last pipe spawned.
  // Starts "full" so the first pipe appears right after the first tap.
  double _spawnDistance = GameConstants.pipeSpacing;
  double? _lastGapY;
  double _readyTime = 0;
  double _deadTime = 0;
  bool _gameOverEventPending = false;

  void _emit(GameEvent event) => onEvent?.call(event);

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

    // Pause: freeze everything. The ticker keeps handing us small dt values,
    // so nothing jumps when we resume.
    if (isPaused) return;

    // After Resume: count 3-2-1 with the world frozen, then continue.
    if (_countdown > 0) {
      _tickCountdown(dt);
      return;
    }

    switch (state) {
      case GameState.ready:
        _advanceWorld(dt);
        _updateReady(dt);
      case GameState.playing:
        _advanceWorld(dt);
        _updatePlaying(dt);
      case GameState.gameOver:
        _updateDead(dt);
    }

    notifyListeners(); // repaint
  }

  /// Ground, clouds and hills scroll, and the wings flap, while the round is
  /// alive (ready + playing). Everything freezes on death.
  void _advanceWorld(double dt) {
    scroll += pipeSpeed * dt;
    animTime += dt;
  }

  // Ready: no gravity, the bird gently floats up and down.
  void _updateReady(double dt) {
    _readyTime += dt;
    bird.velocity = 0;
    bird.y = GameConstants.birdStartY +
        sin(_readyTime * GameConstants.readyBobSpeed) *
            GameConstants.readyBobAmount;
  }

  void _updatePlaying(double dt) {
    bird.update(dt);
    _updatePipes(dt);
    _checkCollisions();
    if (state == GameState.playing) _updateScore(); // no score if we just died
  }

  // Game over: pipes freeze, the bird falls, the screen shakes briefly.
  void _updateDead(double dt) {
    _deadTime += dt;
    bird.update(dt);
    _clampBirdToWorld();

    shake = max(0, shake - dt / GameConstants.shakeDuration);

    if (_gameOverEventPending && _deadTime >= GameConstants.gameOverSoundDelay) {
      _gameOverEventPending = false;
      _emit(GameEvent.gameOver);
    }
  }

  void _clampBirdToWorld() {
    bird.clampTo(
      top: _birdRadiusNorm,
      bottom: GameConstants.groundTop - _birdRadiusNorm,
    );
  }

  // ----------------------------------------------------------------- Pipes

  void _updatePipes(double dt) {
    final dx = pipeSpeed * dt;

    // Spawn by DISTANCE travelled, so spacing stays constant as speed grows.
    _spawnDistance += dx;
    if (_spawnDistance >= GameConstants.pipeSpacing) {
      _spawnDistance -= GameConstants.pipeSpacing;
      _spawnPipe();
    }

    for (final p in pipes) {
      p.x -= dx;
    }

    // Safe removal: pipe is completely off the left edge
    final halfW = _pipeHalfWidthNorm;
    pipes.removeWhere((p) => p.x < -halfW);
  }

  void _spawnPipe() {
    final gap = gapSize; // current gap (shrinks with the score)
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

  // ----------------------------------------------------------------- Score

  /// +1 when the bird passes a pipe's x position, once per pipe.
  void _updateScore() {
    for (final p in pipes) {
      if (!p.passed && p.x < GameConstants.birdX) {
        p.passed = true;
        scoreNotifier.value = scoreNotifier.value + 1;
        _emit(GameEvent.score);
      }
    }
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
    _clampBirdToWorld();

    // High score
    if (score > bestScore) {
      bestScore = score;
      isNewBest = true;
      if (onNewBest != null) unawaited(onNewBest!(score));
    } else {
      isNewBest = false;
    }

    // Death effects
    shake = 1.0;
    _deadTime = 0;
    _gameOverEventPending = true;
    _emit(GameEvent.hit);

    stateNotifier.value = GameState.gameOver;
  }

  // ----------------------------------------------------------------- Pause

  /// Pauses a running round. Does nothing in any other state, so it is safe
  /// to call from anywhere (pause button, app going to the background...).
  void pause() {
    if (state != GameState.playing || isPaused) return;
    _countdown = 0; // cancels a running resume countdown
    countdownNotifier.value = 0;
    pausedNotifier.value = true;
  }

  /// Closes the pause menu and starts the 3-2-1 countdown.
  void resume() {
    if (!isPaused) return;
    pausedNotifier.value = false;
    _countdown = GameConstants.resumeCountdown.toDouble();
    countdownNotifier.value = GameConstants.resumeCountdown;
  }

  void _tickCountdown(double dt) {
    _countdown -= dt;
    if (_countdown <= 0) {
      _countdown = 0;
      countdownNotifier.value = 0;
    } else {
      countdownNotifier.value = _countdown.ceil();
    }
  }

  // ----------------------------------------------------------------- Input

  void onTap() {
    if (isPaused || _countdown > 0) return; // ignore taps while frozen

    switch (state) {
      case GameState.ready:
        _start();
      case GameState.playing:
        bird.flap();
        _emit(GameEvent.flap);
      case GameState.gameOver:
        break; // use the Restart button
    }
  }

  void _start() {
    _spawnDistance = GameConstants.pipeSpacing;
    bird.flap();
    _emit(GameEvent.flap);
    stateNotifier.value = GameState.playing;
  }

  void toggleDebug() {
    debug = !debug;
    notifyListeners();
  }

  /// Puts EVERYTHING back to the starting state (back to "ready").
  void reset() {
    bird.reset();
    pipes.clear();
    _spawnDistance = GameConstants.pipeSpacing;
    _lastGapY = null;
    _readyTime = 0;
    _deadTime = 0;
    _gameOverEventPending = false;
    _countdown = 0;
    countdownNotifier.value = 0;
    pausedNotifier.value = false;
    shake = 0;
    isNewBest = false;
    scoreNotifier.value = 0;
    stateNotifier.value = GameState.ready;
    notifyListeners();
  }

  @override
  void dispose() {
    stateNotifier.dispose();
    scoreNotifier.dispose();
    pausedNotifier.dispose();
    countdownNotifier.dispose();
    super.dispose();
  }
}
