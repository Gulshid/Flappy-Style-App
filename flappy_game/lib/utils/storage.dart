import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/difficulty.dart';

/// Saves and loads small values on the device. Every method catches errors,
/// so a storage problem can never crash the game.
class Storage {
  Storage._();

  // Keys
  static const String _legacyBestKey = 'best'; // before per-difficulty scores
  static const String _mutedKey = 'muted';
  static const String _volumeKey = 'volume';
  static const String _vibrationKey = 'vibration';
  static const String _difficultyKey = 'difficulty';
  static const String _tutorialSeenKey = 'tutorialSeen';
  static const String _skinKey = 'skin';
  static const String _dynamicSkyKey = 'dynamicSky';
  static const String _hitboxesKey = 'showHitboxes';
  static const String gamesPlayedKey = 'gamesPlayed';
  static const String totalScoreKey = 'totalScore';

  static String _bestKey(Difficulty d) => 'best_${d.name}';

  // ------------------------------------------------------------ High scores
  // One best score per difficulty. The old single "best" value is treated as
  // the Normal score, so nobody loses their progress after updating.

  static Future<int> loadBest(Difficulty d) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(_bestKey(d));
      if (value != null) return value;
      return d == Difficulty.normal ? (prefs.getInt(_legacyBestKey) ?? 0) : 0;
    } catch (e) {
      debugPrint('[Storage] loadBest failed: $e');
      return 0;
    }
  }

  /// Only overwrites the stored value if [score] is higher.
  static Future<void> saveBest(int score, Difficulty d) async {
    try {
      final current = await loadBest(d);
      if (score <= current) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestKey(d), score);
    } catch (e) {
      debugPrint('[Storage] saveBest failed: $e');
    }
  }

  /// Removes scores and statistics (settings are kept).
  static Future<void> clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final d in Difficulty.values) {
        await prefs.remove(_bestKey(d));
      }
      await prefs.remove(_legacyBestKey);
      await prefs.remove(gamesPlayedKey);
      await prefs.remove(totalScoreKey);
    } catch (e) {
      debugPrint('[Storage] clearProgress failed: $e');
    }
  }

  // ------------------------------------------------------------ Sound
  static Future<bool> loadMuted() => _getBool(_mutedKey, false);
  static Future<void> saveMuted(bool value) => _setBool(_mutedKey, value);

  static Future<double> loadVolume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_volumeKey) ?? 1.0;
    } catch (e) {
      debugPrint('[Storage] loadVolume failed: $e');
      return 1.0;
    }
  }

  static Future<void> saveVolume(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_volumeKey, value);
    } catch (e) {
      debugPrint('[Storage] saveVolume failed: $e');
    }
  }

  // ------------------------------------------------------------ Preferences
  static Future<bool> loadVibration() => _getBool(_vibrationKey, true);
  static Future<void> saveVibration(bool v) => _setBool(_vibrationKey, v);

  static Future<bool> loadDynamicSky() => _getBool(_dynamicSkyKey, true);
  static Future<void> saveDynamicSky(bool v) => _setBool(_dynamicSkyKey, v);

  static Future<bool> loadShowHitboxes() => _getBool(_hitboxesKey, false);
  static Future<void> saveShowHitboxes(bool v) => _setBool(_hitboxesKey, v);

  static Future<bool> loadTutorialSeen() => _getBool(_tutorialSeenKey, false);
  static Future<void> saveTutorialSeen(bool v) =>
      _setBool(_tutorialSeenKey, v);

  static Future<String?> loadDifficultyName() => _getString(_difficultyKey);
  static Future<void> saveDifficultyName(String v) =>
      _setString(_difficultyKey, v);

  static Future<String?> loadSkinName() => _getString(_skinKey);
  static Future<void> saveSkinName(String v) => _setString(_skinKey, v);

  // ------------------------------------------------------------ Counters
  static Future<int> loadInt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key) ?? 0;
    } catch (e) {
      debugPrint('[Storage] read $key failed: $e');
      return 0;
    }
  }

  static Future<void> saveInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (e) {
      debugPrint('[Storage] write $key failed: $e');
    }
  }

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

  static Future<String?> _getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('[Storage] read $key failed: $e');
      return null;
    }
  }

  static Future<void> _setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('[Storage] write $key failed: $e');
    }
  }
}
