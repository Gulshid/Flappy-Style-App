import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/settings.dart';
import '../utils/theme.dart';

/// Round translucent icon button (back, pause, mute...).
class GlassIconButton extends StatefulWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  /// Design pixels (scaled with ScreenUtil).
  final double size;

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final diameter = widget.size.r;

    Widget button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        if (GameSettings.instance.vibration.value) {
          HapticFeedback.selectionClick();
        }
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _down ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.alpha(AppColors.ink, 0.42),
            border: Border.all(
              color: AppColors.alpha(Colors.white, 0.28),
              width: 1.2,
            ),
          ),
          child: Icon(widget.icon, color: Colors.white, size: diameter * 0.52),
        ),
      ),
    );

    button = Semantics(
      button: true,
      label: widget.tooltip,
      child: button,
    );
    return button;
  }
}
