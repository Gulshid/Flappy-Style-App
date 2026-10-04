import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves and loads small values on the device. Every method catches errors,
/// so a storage problem can never crash the game.
class Storage {
  Storage._();

  static const String _bestKey = 'best';
  static const String _mutedKey = 'muted';
  static const String _vibrationKey = 'vibration';
  static const String _difficultyKey = 'difficulty';
  static const String _tutorialSeenKey = 'tutorialSeen';

  // ------------------------------------------------------------ High score

  static Future<int> loadBest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_bestKey) ?? 0;
    } catch (e) {
      debugPrint('[Storage] loadBest failed: $e');
      return 0;
    }
  }

  /// Only overwrites the stored value if [score] is higher.
  static Future<void> saveBest(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final best = prefs.getInt(_bestKey) ?? 0;
      if (score > best) await prefs.setInt(_bestKey, score);
    } catch (e) {
      debugPrint('[Storage] saveBest failed: $e');
    }
  }

  // ------------------------------------------------------------------ Mute

  static Future<bool> loadMuted() => _getBool(_mutedKey, false);
  static Future<void> saveMuted(bool value) => _setBool(_mutedKey, value);

  // -------------------------------------------------------------- Vibration

  static Future<bool> loadVibration() => _getBool(_vibrationKey, true);
  static Future<void> saveVibration(bool value) =>
      _setBool(_vibrationKey, value);

  // ------------------------------------------------------------ Difficulty
  // Stored as the enum's name ("easy" / "normal" / "hard").

  static Future<String?> loadDifficultyName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_difficultyKey);
    } catch (e) {
      debugPrint('[Storage] loadDifficultyName failed: $e');
      return null;
    }
  }

  static Future<void> saveDifficultyName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_difficultyKey, name);
    } catch (e) {
      debugPrint('[Storage] saveDifficultyName failed: $e');
    }
  }

  // -------------------------------------------------------------- Tutorial

  static Future<bool> loadTutorialSeen() => _getBool(_tutorialSeenKey, false);
  static Future<void> saveTutorialSeen(bool value) =>
      _setBool(_tutorialSeenKey, value);

  // --------------------------------------------------------------- Helpers

  static Future<bool> _getBool(String key, bool fallback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? fallback;
    } catch (e) {
      debugPrint('[Storage] read $key failed: $e');
      return fallback;
    }
  }

  static Future<void> _setBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('[Storage] write $key failed: $e');
    }
  }
}
