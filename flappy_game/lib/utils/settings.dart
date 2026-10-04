import 'package:flutter/foundation.dart';

import '../models/difficulty.dart';
import 'storage.dart';

/// The player's saved preferences. Sound/mute lives in GameAudio (Phase 8);
/// everything else is here.
///
/// Usage:  await GameSettings.instance.init();   // once, in main()
///         GameSettings.instance.difficulty.value
class GameSettings {
  GameSettings._();
  static final GameSettings instance = GameSettings._();

  final ValueNotifier<Difficulty> difficulty =
      ValueNotifier<Difficulty>(Difficulty.normal);
  final ValueNotifier<bool> vibration = ValueNotifier<bool>(true);

  /// True once the player has started a first round (hides the tutorial hint).
  bool tutorialSeen = false;

  Future<void> init() async {
    final name = await Storage.loadDifficultyName();
    difficulty.value = Difficulty.values.firstWhere(
      (d) => d.name == name,
      orElse: () => Difficulty.normal,
    );
    vibration.value = await Storage.loadVibration();
    tutorialSeen = await Storage.loadTutorialSeen();
  }

  Future<void> setDifficulty(Difficulty value) async {
    difficulty.value = value;
    await Storage.saveDifficultyName(value.name);
  }

  Future<void> setVibration(bool value) async {
    vibration.value = value;
    await Storage.saveVibration(value);
  }

  Future<void> markTutorialSeen() async {
    if (tutorialSeen) return;
    tutorialSeen = true;
    await Storage.saveTutorialSeen(true);
  }
}
