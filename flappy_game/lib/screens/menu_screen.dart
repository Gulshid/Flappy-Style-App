import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/storage.dart';
import '../widgets/game_text.dart';
import 'game_screen.dart';

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Buttons never get wider than 80% of the screen
              final buttonWidth = min(260.w, constraints.maxWidth * 0.8);

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                        SizedBox(height: 40.h),
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
                          child: const OutlinedButton(
                            onPressed: null, // Settings screen comes in Phase 9
                            child: Text('Settings (soon)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
