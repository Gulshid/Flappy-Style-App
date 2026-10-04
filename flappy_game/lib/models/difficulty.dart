import 'dart:math';

/// The three difficulty levels the player can pick in Settings.
enum Difficulty { easy, normal, hard }

/// The difficulty CURVE: how fast the pipes move and how big the gap is,
/// based on the current score. Every value has a cap, so the game gets
/// harder as you score but never becomes impossible.
///
/// Units: speed = screen widths per second, gap = screen heights.
extension DifficultyConfig on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Easy',
        Difficulty.normal => 'Normal',
        Difficulty.hard => 'Hard',
      };

  String get description => switch (this) {
        Difficulty.easy => 'Slower pipes and a wider gap. Relaxed.',
        Difficulty.normal => 'The classic experience.',
        Difficulty.hard => 'Fast pipes and a tight gap. Good luck!',
      };

  // ---- starting values (score 0)
  double get _baseSpeed => switch (this) {
        Difficulty.easy => 0.30,
        Difficulty.normal => 0.35,
        Difficulty.hard => 0.40,
      };

  double get _baseGap => switch (this) {
        Difficulty.easy => 0.32,
        Difficulty.normal => 0.28,
        Difficulty.hard => 0.25,
      };

  // ---- how much harder it gets per point scored
  double get _speedPerPoint => switch (this) {
        Difficulty.easy => 0.005,
        Difficulty.normal => 0.008,
        Difficulty.hard => 0.010,
      };

  double get _gapShrinkPerPoint => switch (this) {
        Difficulty.easy => 0.0015,
        Difficulty.normal => 0.0020,
        Difficulty.hard => 0.0025,
      };

  // ---- caps (the "sensible limits")
  double get _maxSpeed => switch (this) {
        Difficulty.easy => 0.45,
        Difficulty.normal => 0.55,
        Difficulty.hard => 0.65,
      };

  double get _minGap => switch (this) {
        Difficulty.easy => 0.26,
        Difficulty.normal => 0.22,
        Difficulty.hard => 0.20,
      };

  /// Pipe speed for the given score, capped at the maximum.
  double pipeSpeed(int score) => min(_maxSpeed, _baseSpeed + score * _speedPerPoint);

  /// Gap size for the given score, never smaller than the minimum.
  double gapSize(int score) => max(_minGap, _baseGap - score * _gapShrinkPerPoint);
}
