/// All tunable numbers live here. Vertical values are in "screen heights"
/// (0.0 = top, 1.0 = bottom) and horizontal values in "screen widths", so
/// physics behaves the same on every screen.
///
/// Pipe SPEED and GAP SIZE now come from the difficulty setting
/// (see models/difficulty.dart), because they change with the score.
class GameConstants {
  GameConstants._();

  // ---------------------------------------------------------------- Physics
  // (screen heights per second / per second squared)
  static const double gravity = 2.2;
  static const double flapForce = -0.75;
  static const double maxFallSpeed = 1.2;

  // ------------------------------------------------------------------- Bird
  static const double birdX = 0.30; // fraction of screen WIDTH
  static const double birdStartY = 0.5;
  static const double birdRadiusDesign = 18; // design px, scaled with .r
  static const double hitboxShrink = 0.9; // hitbox = 90% of visual size

  // Ready state: the bird bobs up and down while waiting for the first tap
  static const double readyBobSpeed = 4.0; // radians per second
  static const double readyBobAmount = 0.015; // screen heights

  // ------------------------------------------------------------------ World
  static const double groundHeight = 0.10; // fraction of screen height
  static double get groundTop => 1.0 - groundHeight;

  // ------------------------------------------------------------------ Pipes
  static const double pipeWidthDesign = 64; // design px, scaled with .w

  /// Distance between two pipes in screen widths. Spawning is by DISTANCE
  /// (not time), so the spacing stays the same even when the pipes speed up.
  static const double pipeSpacing = 0.6;

  static const double pipeGapMargin = 0.08; // min space gap <-> ceiling/ground
  static const double pipeMaxGapShift = 0.25; // max change vs previous gap
  static const double pipeCapHeight = 0.03; // pipe cap, screen heights

  // -------------------------------------------------------------- Collision
  static const bool ceilingKills = true; // false = bird just stops at the top

  // ------------------------------------------------------------- Visuals
  /// Bird sprite width as a multiple of the bird radius (sprite is 80x64).
  static const double birdSpriteWidthFactor = 2.3;

  /// Wing animation: frames per second, and the frame order (0=up,1=mid,2=down).
  static const double wingFps = 10;
  static const List<int> wingSequence = [0, 1, 2, 1];

  /// Parallax: how fast each layer scrolls compared to the pipes/ground (1.0).
  static const double cloudsParallax = 0.08;
  static const double hillsParallax = 0.25;
  static const double groundParallax = 1.0;

  /// Layer placement, in screen heights.
  static const double cloudsTop = 0.04;
  static const double cloudsHeight = 0.30;
  static const double hillsHeight = 0.18; // sits right above the ground

  /// Screen shake on death.
  static const double shakeDuration = 0.35; // seconds
  static const double shakeMagnitude = 0.012; // fraction of screen width

  // --------------------------------------------------------------- Feedback
  /// Delay between the crash ("hit") and the "game over" jingle.
  static const double gameOverSoundDelay = 0.45; // seconds

  // ------------------------------------------------- Polish (Phase 9)
  /// After pressing Resume, a 3-2-1 countdown runs before play continues.
  static const int resumeCountdown = 3; // seconds

  /// The play area is never wider than height * this value. On phones and
  /// portrait tablets it has no effect; on wide screens (foldables, desktop,
  /// landscape) the game stays centred instead of stretching.
  static const double maxPlayAspect = 0.75; // width / height

  // ------------------------------------------- Sky + effects (Phase 11)
  /// The sky moves to the next stage (day, sunset, night, dawn) every N points.
  static const int skyStageLength = 10;

  /// How quickly the sky blends to the next stage (higher = faster).
  static const double skySmoothing = 1.6;

  /// Upper limit for live particles, so effects can never slow the game down.
  static const int maxParticles = 140;

  /// White flash on impact (0 = off, 1 = full white).
  static const double flashStrength = 0.5;

  // ------------------------------------------------------------------- Loop
  // Never simulate a huge step (e.g. after a hiccup or coming back from pause)
  static const double maxDt = 0.05;

  // ------------------------------------------------------------------ Debug
  // Can still be toggled at runtime with the bug icon.
  static const bool debugHitboxes = false;
}
