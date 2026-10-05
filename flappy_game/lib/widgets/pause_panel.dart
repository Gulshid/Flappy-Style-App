import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_button.dart';
import 'game_text.dart';
import 'glass_card.dart';
import 'mute_button.dart';

/// Panel shown over a dimmed game while paused.
class PausePanel extends StatelessWidget {
  const PausePanel({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onMenu,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: 280.w,
      radius: 28,
      padding: EdgeInsets.fromLTRB(20.r, 20.r, 20.r, 18.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 44.r), // balances the mute button
              const GameText('Paused', fontSize: 30),
              const MuteButton(),
            ],
          ),
          SizedBox(height: 18.h),
          AppButton(
            label: 'Resume',
            icon: Icons.play_arrow_rounded,
            onPressed: onResume,
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Restart',
                  icon: Icons.replay_rounded,
                  style: AppButtonStyle.secondary,
                  height: 46,
                  fontSize: 15,
                  onPressed: onRestart,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: AppButton(
                  label: 'Menu',
                  icon: Icons.home_rounded,
                  style: AppButtonStyle.secondary,
                  height: 46,
                  fontSize: 15,
                  onPressed: onMenu,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
