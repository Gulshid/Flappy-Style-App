/// All tunable numbers live here. Vertical values are in "screen heights"
/// (0.0 = top, 1.0 = bottom) and horizontal values in "screen widths", so
/// physics behaves the same on every screen.
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
  static const double pipeSpeed = 0.35; // screen widths per second
  static const double pipeSpawnInterval = 1.7; // seconds between pipes
  static const double pipeGapSize = 0.28; // screen heights
  static const double pipeGapMargin = 0.08; // min space gap <-> ceiling/ground
  static const double pipeMaxGapShift = 0.25; // max change vs previous gap
  static const double pipeCapHeight = 0.03; // visual lip, screen heights

  // -------------------------------------------------------------- Collision
  static const bool ceilingKills = true; // false = bird just stops at the top

  // ------------------------------------------------------------------- Loop
  // Never simulate a huge step (e.g. after a hiccup)
  static const double maxDt = 0.05;

  // ------------------------------------------------------------------ Debug
  // Can still be toggled at runtime with the bug icon.
  static const bool debugHitboxes = false;
}
