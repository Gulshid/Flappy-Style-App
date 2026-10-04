/// All tunable numbers live here. Vertical values are in "screen heights"
/// (0.0 = top, 1.0 = bottom) so physics behaves the same on every screen.
class GameConstants {
  GameConstants._();

  // Physics (screen heights per second / per second squared)
  static const double gravity = 2.2;
  static const double flapForce = -0.75;
  static const double maxFallSpeed = 1.2;

  // Bird
  static const double birdX = 0.30; // fraction of screen WIDTH
  static const double birdStartY = 0.5;
  static const double birdRadiusDesign = 18; // design px, scaled with .r
  static const double hitboxShrink = 0.9; // used in Phase 4

  // World
  static const double groundHeight = 0.10; // fraction of screen height
  static double get groundTop => 1.0 - groundHeight;

  // Loop safety: never simulate a huge step (e.g. after a hiccup)
  static const double maxDt = 0.05;

  // Debug
  static const bool debugHitboxes = true;
}
