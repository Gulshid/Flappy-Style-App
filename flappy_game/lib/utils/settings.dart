import 'package:flutter/foundation.dart';

import '../models/difficulty.dart';
import '../models/skin.dart';
import 'storage.dart';

/// The player's saved preferences. Sound lives in GameAudio; scores and
/// statistics live in PlayerStats; everything else is here.
///
/// Usage:  await GameSettings.instance.init();   // once, in main()
///         GameSettings.instance.difficulty.value
class GameSettings {
  GameSettings._();
  static final GameSettings instance = GameSettings._();

  final ValueNotifier<Difficulty> difficulty =
      ValueNotifier<Difficulty>(Difficulty.normal);
  final ValueNotifier<bool> vibration = ValueNotifier<bool>(true);
  final ValueNotifier<BirdSkin> skin = ValueNotifier<BirdSkin>(BirdSkin.classic);

  /// Day turns to night as the score grows.
  final ValueNotifier<bool> dynamicSky = ValueNotifier<bool>(true);

  /// Draws the collision boxes (for debugging / curious players).
  final ValueNotifier<bool> showHitboxes = ValueNotifier<bool>(false);

  /// True once the player has started a first round (hides the tutorial hint).
  bool tutorialSeen = false;

  Future<void> init() async {
    final name = await Storage.loadDifficultyName();
    difficulty.value = Difficulty.values.firstWhere(
      (d) => d.name == name,
      orElse: () => Difficulty.normal,
    );
    final skinName = await Storage.loadSkinName();
    skin.value = BirdSkin.values.firstWhere(
      (s) => s.name == skinName,
      orElse: () => BirdSkin.classic,
    );
    vibration.value = await Storage.loadVibration();
    dynamicSky.value = await Storage.loadDynamicSky();
    showHitboxes.value = await Storage.loadShowHitboxes();
    tutorialSeen = await Storage.loadTutorialSeen();
  }

  Future<void> setDifficulty(Difficulty value) async {
    difficulty.value = value;
    await Storage.saveDifficultyName(value.name);
  }

  Future<void> setSkin(BirdSkin value) async {
    skin.value = value;
    await Storage.saveSkinName(value.name);
  }

  Future<void> setVibration(bool value) async {
    vibration.value = value;
    await Storage.saveVibration(value);
  }

  Future<void> setDynamicSky(bool value) async {
    dynamicSky.value = value;
    await Storage.saveDynamicSky(value);
  }

  Future<void> setShowHitboxes(bool value) async {
    showHitboxes.value = value;
    await Storage.saveShowHitboxes(value);
  }

  Future<void> markTutorialSeen() async {
    if (tutorialSeen) return;
    tutorialSeen = true;
    await Storage.saveTutorialSeen(true);
  }
}
