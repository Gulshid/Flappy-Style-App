import '../utils/constants.dart';

class Bird {
  /// Vertical position, 0.0 (top) to 1.0 (bottom) in screen heights.
  double y = GameConstants.birdStartY;

  /// Vertical velocity in screen heights per second (negative = up).
  double velocity = 0;

  void flap() => velocity = GameConstants.flapForce;

  void update(double dt) {
    velocity += GameConstants.gravity * dt;
    if (velocity > GameConstants.maxFallSpeed) {
      velocity = GameConstants.maxFallSpeed;
    }
    y += velocity * dt;
  }

  /// Keeps the bird between ceiling and ground (values are bird-centre limits).
  void clampTo({required double top, required double bottom}) {
    if (y < top) {
      y = top;
      if (velocity < 0) velocity = 0;
    } else if (y > bottom) {
      y = bottom;
      velocity = 0;
    }
  }

  /// Rotation in radians: nose up when rising, nose down when falling.
  double get angle => velocity.clamp(-0.75, 1.2) * 0.9;

  void reset() {
    y = GameConstants.birdStartY;
    velocity = 0;
  }
}
