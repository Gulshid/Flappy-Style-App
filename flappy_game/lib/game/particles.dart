import 'dart:math';
import 'dart:ui';

import '../utils/constants.dart';

/// puff    = soft white dot behind the bird when it flaps
/// spark   = golden sparkle when you score
/// feather = falling feather when you crash
enum ParticleKind { puff, spark, feather }

class Particle {
  Particle({
    required this.kind,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
    required this.color,
    this.gravity = 0,
    this.rotation = 0,
    this.spin = 0,
  }) : maxLife = life;

  final ParticleKind kind;
  final Color color;
  final double size;
  final double gravity;
  final double spin;
  final double maxLife;

  double x;
  double y;
  double vx;
  double vy;
  double life;
  double rotation;

  /// 1.0 when fresh, 0.0 when about to disappear.
  double get t => (life / maxLife).clamp(0.0, 1.0).toDouble();
}

/// Small effects system. Positions are in pixels; every speed and size is
/// derived from [unit] (the play-area height) so effects look the same on
/// every screen. The list is capped, so it can never hurt performance.
class ParticleSystem {
  ParticleSystem([Random? rng]) : _rng = rng ?? Random();

  final Random _rng;
  final List<Particle> items = [];

  bool get isEmpty => items.isEmpty;

  void clear() => items.clear();

  double _r() => _rng.nextDouble();

  void _add(Particle p) {
    if (items.length >= GameConstants.maxParticles) items.removeAt(0);
    items.add(p);
  }

  void puff(Offset at, double unit) {
    for (var i = 0; i < 3; i++) {
      _add(Particle(
        kind: ParticleKind.puff,
        x: at.dx - unit * 0.02,
        y: at.dy + unit * 0.012,
        vx: -unit * (0.10 + _r() * 0.14),
        vy: unit * (_r() - 0.2) * 0.12,
        life: 0.35 + _r() * 0.2,
        size: unit * (0.007 + _r() * 0.006),
        color: const Color(0xFFFFFFFF),
      ));
    }
  }

  void sparkle(Offset at, double unit) {
    const count = 10;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + _r() * 0.5;
      final speed = unit * (0.22 + _r() * 0.22);
      _add(Particle(
        kind: ParticleKind.spark,
        x: at.dx,
        y: at.dy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 0.5 + _r() * 0.25,
        size: unit * (0.008 + _r() * 0.007),
        color: i.isEven ? const Color(0xFFFFD54F) : const Color(0xFFFFFFFF),
        rotation: _r() * pi,
        spin: (_r() - 0.5) * 8,
      ));
    }
  }

  void burst(Offset at, double unit) {
    const colors = [Color(0xFFFFE082), Color(0xFFFFFFFF), Color(0xFFFFB74D)];
    for (var i = 0; i < 16; i++) {
      final angle = _r() * 2 * pi;
      final speed = unit * (0.18 + _r() * 0.42);
      _add(Particle(
        kind: ParticleKind.feather,
        x: at.dx,
        y: at.dy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - unit * 0.15,
        gravity: unit * 0.9,
        life: 0.8 + _r() * 0.4,
        size: unit * (0.012 + _r() * 0.008),
        color: colors[i % colors.length],
        rotation: _r() * pi,
        spin: (_r() - 0.5) * 16,
      ));
    }
  }

  void update(double dt) {
    for (final p in items) {
      p.life -= dt;
      p.vy += p.gravity * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rotation += p.spin * dt;
    }
    items.removeWhere((p) => p.life <= 0);
  }
}
