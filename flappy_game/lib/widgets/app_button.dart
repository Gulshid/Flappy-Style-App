import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/settings.dart';
import '../utils/theme.dart';

enum AppButtonStyle { primary, secondary, danger }

/// Pill button that squeezes slightly when pressed and gives a light haptic
/// tick (if vibration is on in Settings).
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = AppButtonStyle.primary,
    this.height = 52,
    this.fontSize = 18,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonStyle style;

  /// Design pixels (scaled with ScreenUtil).
  final double height;
  final double fontSize;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    final (List<Color> colors, Color fg, Color? borderColor) =
        switch (widget.style) {
      AppButtonStyle.primary => (
          [AppColors.amberLight, AppColors.amber],
          AppColors.onAmber,
          null,
        ),
      AppButtonStyle.secondary => (
          [
            AppColors.alpha(Colors.white, 0.30),
            AppColors.alpha(Colors.white, 0.16),
          ],
          Colors.white,
          AppColors.alpha(Colors.white, 0.35),
        ),
      AppButtonStyle.danger => (
          [const Color(0xFFFF8585), const Color(0xFFE03E3E)],
          Colors.white,
          null,
        ),
    };

    final glow = widget.style == AppButtonStyle.primary
        ? [
            BoxShadow(
              color: AppColors.alpha(AppColors.amber, 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ]
        : null;

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setDown(true) : null,
        onTapUp: enabled ? (_) => _setDown(false) : null,
        onTapCancel: enabled ? () => _setDown(false) : null,
        onTap: enabled
            ? () {
                if (GameSettings.instance.vibration.value) {
                  HapticFeedback.selectionClick();
                }
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 90),
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: Container(
              height: widget.height.h,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height.h),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
                border: borderColor == null
                    ? null
                    : Border.all(color: borderColor, width: 1.2),
                boxShadow: glow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: fg, size: (widget.fontSize + 6).r),
                    SizedBox(width: 8.w),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appStyle(widget.fontSize,
                          color: fg, weight: FontWeight.w800, spacing: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
