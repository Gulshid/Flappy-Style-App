import 'package:flutter/foundation.dart';

import '../models/difficulty.dart';
import 'storage.dart';

/// Best score per difficulty plus lifetime statistics.
///
/// Usage:  await PlayerStats.instance.init();        // once, in main()
///         PlayerStats.instance.recordRound(12, d);  // when a round ends
///
/// Listen to [revision] to rebuild widgets when anything changes.
class PlayerStats {
  PlayerStats._();
  static final PlayerStats instance = PlayerStats._();

  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  final Map<Difficulty, int> _best = {};
  int gamesPlayed = 0;

  /// Total pipes cleared across all rounds.
  int totalScore = 0;

  Future<void> init() async {
    for (final d in Difficulty.values) {
      _best[d] = await Storage.loadBest(d);
    }
    gamesPlayed = await Storage.loadInt(Storage.gamesPlayedKey);
    totalScore = await Storage.loadInt(Storage.totalScoreKey);
    revision.value++;
  }

  int bestFor(Difficulty d) => _best[d] ?? 0;

  int get overallBest =>
      _best.values.fold<int>(0, (a, b) => a > b ? a : b);

  double get averageScore => gamesPlayed == 0 ? 0 : totalScore / gamesPlayed;

  Future<void> recordRound(int score, Difficulty d) async {
    gamesPlayed++;
    totalScore += score;
    if (score > bestFor(d)) _best[d] = score;
    revision.value++;

    await Storage.saveBest(score, d);
    await Storage.saveInt(Storage.gamesPlayedKey, gamesPlayed);
    await Storage.saveInt(Storage.totalScoreKey, totalScore);
  }

  Future<void> reset() async {
    _best.clear();
    gamesPlayed = 0;
    totalScore = 0;
    revision.value++;
    await Storage.clearProgress();
  }
}
