import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/difficulty.dart';
import '../utils/settings.dart';
import '../utils/storage.dart';
import '../widgets/game_text.dart';
import '../widgets/mute_button.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _best = 0;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final best = await Storage.loadBest();
    if (mounted) setState(() => _best = best);
  }

  Future<void> _play() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GameScreen()),
    );
    // Back from the game: refresh the best score
    _loadBest();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  // Buttons never get wider than 80% of the screen
                  final buttonWidth = min(260.w, constraints.maxWidth * 0.8);

                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flutter_dash,
                                size: 96.r, color: const Color(0xFFFFD54F)),
                            SizedBox(height: 12.h),
                            const GameText('Flappy Game', fontSize: 40),
                            SizedBox(height: 8.h),
                            GameText('Best: $_best', fontSize: 20),
                            SizedBox(height: 4.h),
                            // Updates by itself when changed in Settings
                            ValueListenableBuilder<Difficulty>(
                              valueListenable: GameSettings.instance.difficulty,
                              builder: (context, d, _) =>
                                  GameText(d.label, fontSize: 16),
                            ),
                            SizedBox(height: 36.h),
                            SizedBox(
                              width: buttonWidth,
                              height: 52.h,
                              child: ElevatedButton(
                                onPressed: _play,
                                child: Text('Play',
                                    style: TextStyle(fontSize: 22.sp)),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            SizedBox(
                              width: buttonWidth,
                              height: 44.h,
                              child: OutlinedButton(
                                onPressed: _openSettings,
                                child: Text('Settings',
                                    style: TextStyle(fontSize: 18.sp)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Mute toggle (top right)
              Positioned(
                top: 8.h,
                right: 8.w,
                child: const MuteButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
