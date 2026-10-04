import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves and loads small values on the device.
/// Phase 8 will reuse this for the mute setting.
class Storage {
  Storage._();

  static const String _bestKey = 'best';

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
}
