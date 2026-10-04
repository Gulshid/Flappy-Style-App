import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/difficulty.dart';
import '../utils/audio.dart';
import '../utils/settings.dart';
import '../widgets/game_text.dart';

/// Sound, vibration and difficulty. Everything is saved immediately and
/// remembered the next time the app starts.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = GameAudio.instance;
    final settings = GameSettings.instance;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4EC0CA), Color(0xFFB8E8F0)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Card is never wider than 80% of the screen or 480 design px,
              // so it looks right on small phones and on tablets.
              final cardWidth = min(480.w, constraints.maxWidth * 0.9);

              return Column(
                children: [
                  // Header: back button + title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 28.r,
                            shadows: const [
                              Shadow(blurRadius: 6, color: Colors.black54),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        const GameText('Settings', fontSize: 30),
                      ],
                    ),
                  ),

                  // Scrollable body (never overflows on short screens)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: Container(
                          width: cardWidth,
                          margin: EdgeInsets.symmetric(vertical: 12.h),
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                                color: const Color(0xFF8D6E63), width: 3),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ---- Sound
                              ValueListenableBuilder<bool>(
                                valueListenable: audio.muted,
                                builder: (context, muted, _) => SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: _label('Sound'),
                                  secondary: Icon(
                                    muted ? Icons.volume_off : Icons.volume_up,
                                    color: const Color(0xFF5D4037),
                                  ),
                                  value: !muted,
                                  onChanged: (_) => audio.toggleMute(),
                                ),
                              ),

                              // ---- Vibration
                              ValueListenableBuilder<bool>(
                                valueListenable: settings.vibration,
                                builder: (context, on, _) => SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: _label('Vibration'),
                                  secondary: const Icon(
                                    Icons.vibration,
                                    color: Color(0xFF5D4037),
                                  ),
                                  value: on,
                                  onChanged: (value) {
                                    settings.setVibration(value);
                                    // Small buzz so you can feel it is on
                                    if (value) HapticFeedback.mediumImpact();
                                  },
                                ),
                              ),

                              const Divider(),
                              SizedBox(height: 8.h),

                              // ---- Difficulty
                              _label('Difficulty'),
                              SizedBox(height: 10.h),
                              ValueListenableBuilder<Difficulty>(
                                valueListenable: settings.difficulty,
                                builder: (context, current, _) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: SegmentedButton<Difficulty>(
                                        showSelectedIcon: false,
                                        segments: [
                                          for (final d in Difficulty.values)
                                            ButtonSegment<Difficulty>(
                                              value: d,
                                              label: Text(d.label),
                                            ),
                                        ],
                                        selected: {current},
                                        onSelectionChanged: (selection) =>
                                            settings.setDifficulty(
                                                selection.first),
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Text(
                                      current.description,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: const Color(0xFF795548),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5D4037),
        ),
      );
}
