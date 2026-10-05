import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/bird.dart';
import '../models/difficulty.dart';
import '../models/game_state.dart';
import '../models/pipe.dart';
import '../utils/constants.dart';
import 'particles.dart';
import 'sky_palette.dart';

/// Owns all game state and rules. Knows nothing about widgets, painting,
/// storage or audio. It is a [ChangeNotifier] so the painter can repaint
/// without rebuilding the widget tree every frame.
class GameController extends ChangeNotifier {
  /// [difficulty] decides the pipe speed and gap size curve.
  /// [dynamicSky] lets the sky change (day, sunset, night, dawn) with the score.
  /// [rng] can be injected in tests for predictable pipes.
  /// [onNewBest] is called when a round ends with a new high score.
  /// [onRoundEnd] is called at the end of EVERY round (for statistics).
  /// [onEvent] is called for flap / score / hit / gameOver so the screen can
  /// play sounds and vibrate.
  GameController({
    this.difficulty = Difficulty.normal,
    this.dynamicSky = true,
    Random? rng,
    this.onNewBest,
    this.onRoundEnd,
    this.onEvent,
  })  : _rng = rng ?? Random(),
        particles = ParticleSystem(rng);

  final Difficulty difficulty;
  final bool dynamicSky;
  final Random _rng;
  final Future<void> Function(int score)? onNewBest;
  final void Function(int score)? onRoundEnd;
  final void Function(GameEvent event)? onEvent;

  final Bird bird = Bird();
  final List<Pipe> pipes = [];
  final ParticleSystem particles;

  // ----------------------------------------------------------------- State
  final ValueNotifier<GameState> stateNotifier =
      ValueNotifier<GameState>(GameState.ready);
  GameState get state => stateNotifier.value;

  // ----------------------------------------------------------------- Score
  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  int get score => scoreNotifier.value;

  int bestScore = 0;
  bool isNewBest = false;

  /// Called after the saved high score has been loaded.
  void setBestScore(int value) {
    if (value > bestScore) bestScore = value;
  }

  // ------------------------------------------------------------ Difficulty
  /// Current pipe speed (screen widths / second): grows with the score.
  double get pipeSpeed => difficulty.pipeSpeed(score);

  /// Current gap size (screen heights): shrinks with the score.
  double get gapSize => difficulty.gapSize(score);

  // ----------------------------------------------------------------- Pause
  /// True while the pause menu is open.
  final ValueNotifier<bool> pausedNotifier = ValueNotifier<bool>(false);
  bool get isPaused => pausedNotifier.value;

  /// 3, 2, 1 after pressing Resume; 0 when there is no countdown.
  final ValueNotifier<int> countdownNotifier = ValueNotifier<int>(0);
  double _countdown = 0;

  // -------------------------------------------------------- Visual state
  /// How far the world has scrolled, in screen widths.
  double scroll = 0;

  /// Seconds of animation time (drives wing flapping and star twinkle).
  double animTime = 0;

  /// Screen shake strength: 1.0 right after a crash, fading to 0.
  double shake = 0;

  /// The sky right now (blends towards the palette for the current score).
  SkyPalette sky = SkyPalette.day;

  // ---------------------------------------------------- Layout (pixels)
  Size viewSize = Size.zero;
  double birdRadiusPx = 0;
  double pipeWidthPx = 0;

  bool debug = GameConstants.debugHitboxes;

  // ---------------------------------------------------- Internal timers
  double _spawnDistance = GameConstants.pipeSpacing;
  double? _lastGapY;
  double _readyTime = 0;
  double _deadTime = 0;
  bool _gameOverEventPending = false;

  void _emit(GameEvent event) => onEvent?.call(event);

  // ---------------------------------------------------------------- Layout

  /// Called by the screen's LayoutBuilder whenever the layout changes.
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

  /// Bird centre in pixels.
  Offset get birdCenter => Offset(
        viewSize.width * GameConstants.birdX,
        bird.y * viewSize.height,
      );

  /// Bird hitbox in pixel space, slightly smaller than the drawn bird.
  Rect get birdRect {
    final half = birdRadiusPx * GameConstants.hitboxShrink;
    return Rect.fromCenter(
        center: birdCenter, width: half * 2, height: half * 2);
  }

  // ---------------------------------------------------------------- Update

  void update(double dt) {
    if (viewSize.isEmpty) return;

    // Pause: freeze everything.
    if (isPaused) return;

    // After Resume: count 3-2-1 with the world frozen, then continue.
    if (_countdown > 0) {
      _tickCountdown(dt);
      return;
    }

    var needsRepaint = true;
    switch (state) {
      case GameState.ready:
        _advanceWorld(dt);
        _updateReady(dt);
      case GameState.playing:
        _advanceWorld(dt);
        _updatePlaying(dt);
      case GameState.gameOver:
        needsRepaint = _updateDead(dt);
    }

    if (needsRepaint) notifyListeners(); // repaint
  }

  /// Ground, clouds and hills scroll, the wings flap, the sky blends and
  /// particles move, while the round is alive (ready + playing).
  void _advanceWorld(double dt) {
    scroll += pipeSpeed * dt;
    animTime += dt;
    _updateSky(dt);
    particles.update(dt);
  }

  void _updateSky(double dt) {
    final target = dynamicSky ? SkyPalette.forScore(score) : SkyPalette.day;
    final k = 1 - exp(-GameConstants.skySmoothing * dt);
    sky = SkyPalette.lerp(sky, target, k);
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

  /// Game over: pipes freeze, the bird falls, the screen shakes briefly and
  /// feathers fly. Returns false once everything has settled, so the painter
  /// stops redrawing an unchanged picture.
  bool _updateDead(double dt) {
    _deadTime += dt;

    final beforeY = bird.y;
    bird.update(dt);
    _clampBirdToWorld();
    particles.update(dt);

    final hadShake = shake > 0;
    shake = max(0, shake - dt / GameConstants.shakeDuration);

    if (_gameOverEventPending && _deadTime >= GameConstants.gameOverSoundDelay) {
      _gameOverEventPending = false;
      _emit(GameEvent.gameOver);
    }

    return _gameOverEventPending ||
        hadShake ||
        !particles.isEmpty ||
        (bird.y - beforeY).abs() > 1e-6;
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
        particles.sparkle(birdCenter, viewSize.height);
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
    onRoundEnd?.call(score);

    // Death effects
    shake = 1.0;
    _deadTime = 0;
    _gameOverEventPending = true;
    particles.burst(birdCenter, viewSize.height);
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
        _flap();
      case GameState.gameOver:
        break; // use the Restart button
    }
  }

  void _flap() {
    bird.flap();
    particles.puff(birdCenter, viewSize.height);
    _emit(GameEvent.flap);
  }

  void _start() {
    _spawnDistance = GameConstants.pipeSpacing;
    _flap();
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
    particles.clear();
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
