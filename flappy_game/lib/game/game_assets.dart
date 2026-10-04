import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// All game images, decoded ONCE before the first frame so nothing flickers
/// while the game is running. Call `await GameAssets.load()` in main().
class GameAssets {
  GameAssets._({
    required this.birdFrames,
    required this.pipeBody,
    required this.pipeCapTop,
    required this.pipeCapBottom,
    required this.ground,
    required this.clouds,
    required this.hills,
  });

  /// 3 wing frames: up, middle, down.
  final List<ui.Image> birdFrames;
  final ui.Image pipeBody;

  /// Cap of the TOP pipe (sits at its lower end).
  final ui.Image pipeCapTop;

  /// Cap of the BOTTOM pipe (sits at its upper end).
  final ui.Image pipeCapBottom;

  final ui.Image ground;
  final ui.Image clouds;
  final ui.Image hills;

  static GameAssets? _instance;

  /// Available after [load] has completed.
  static GameAssets get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('GameAssets.load() must be awaited in main() first.');
    }
    return i;
  }

  static Future<GameAssets> load() async {
    Future<ui.Image> image(String file) async {
      final data = await rootBundle.load('assets/images/$file');
      return decodeImageFromList(data.buffer.asUint8List());
    }

    final birdFrames = await Future.wait([
      image('bird_0.png'),
      image('bird_1.png'),
      image('bird_2.png'),
    ]);

    final assets = GameAssets._(
      birdFrames: birdFrames,
      pipeBody: await image('pipe_body.png'),
      pipeCapTop: await image('pipe_cap_top.png'),
      pipeCapBottom: await image('pipe_cap_bottom.png'),
      ground: await image('ground.png'),
      clouds: await image('clouds.png'),
      hills: await image('hills.png'),
    );
    _instance = assets;
    return assets;
  }
}
