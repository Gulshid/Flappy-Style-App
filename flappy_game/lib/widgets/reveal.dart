import 'package:flutter/material.dart';

/// Fades and slides [child] in while [animation] runs between [start] and
/// [end] (both 0..1). Several Reveals on one controller give a staggered
/// entrance.
class Reveal extends StatelessWidget {
  const Reveal({
    super.key,
    required this.animation,
    required this.child,
    this.start = 0,
    this.end = 1,
    this.offset = const Offset(0, 0.12),
  });

  final Animation<double> animation;
  final Widget child;
  final double start;
  final double end;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final eased = animation.drive(
      CurveTween(curve: Interval(start, end, curve: Curves.easeOutCubic)),
    );
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: eased.drive(Tween<Offset>(begin: offset, end: Offset.zero)),
        child: child,
      ),
    );
  }
}

/// Gently grows and shrinks its child forever (used for "tap to start").
class Pulse extends StatefulWidget {
  const Pulse({
    super.key,
    required this.child,
    this.minScale = 0.94,
    this.maxScale = 1.06,
    this.duration = const Duration(milliseconds: 900),
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)
        ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller
          .drive(CurveTween(curve: Curves.easeInOut))
          .drive(Tween<double>(begin: widget.minScale, end: widget.maxScale)),
      child: widget.child,
    );
  }
}
