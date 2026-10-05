import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'game_text.dart';
import 'glass_icon_button.dart';
import 'world_background.dart';

/// Shared layout for the secondary screens (Settings, Statistics): the live
/// world behind, a back button with the title, and a scrolling, centred body.
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WorldBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Never wider than 480 design px or 92% of the screen.
              final bodyWidth = min(480.w, constraints.maxWidth * 0.92);

              return Column(
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    child: Row(
                      children: [
                        GlassIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        SizedBox(width: 14.w),
                        GameText(title, fontSize: 28),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: 24.h),
                      child: Center(
                        child: SizedBox(width: bodyWidth, child: child),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
