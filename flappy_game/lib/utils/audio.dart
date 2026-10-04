import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'storage.dart';

/// The four game sounds (files live in assets/audio/).
enum Sfx { flap, score, hit, gameOver }

/// Plays short sound effects with low latency and remembers the mute setting.
///
/// Usage:  await GameAudio.instance.init();   // once, in main()
///         GameAudio.instance.play(Sfx.flap);
///
/// If audio fails to start (unsupported platform, missing file...) the game
/// keeps working silently.
class GameAudio {
  GameAudio._();
  static final GameAudio instance = GameAudio._();

  static const Map<Sfx, String> _files = {
    Sfx.flap: 'audio/flap.wav',
    Sfx.score: 'audio/score.wav',
    Sfx.hit: 'audio/hit.wav',
    Sfx.gameOver: 'audio/game_over.wav',
  };

  /// Listen to this to show the speaker icon.
  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  final Map<Sfx, AudioPlayer> _players = {};
  bool _ready = false;

  /// Loads the saved mute setting and preloads every sound, one player per
  /// sound, in low-latency mode.
  Future<void> init() async {
    muted.value = await Storage.loadMuted();
    try {
      for (final entry in _files.entries) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(entry.value)); // preload
        _players[entry.key] = player;
      }
      _ready = true;
    } catch (e) {
      debugPrint('[GameAudio] init failed, running silent: $e');
    }
  }

  Future<void> play(Sfx sfx) async {
    if (muted.value || !_ready) return;
    try {
      await _players[sfx]?.play(AssetSource(_files[sfx]!));
    } catch (e) {
      debugPrint('[GameAudio] play($sfx) failed: $e');
    }
  }

  Future<void> toggleMute() async {
    muted.value = !muted.value;
    await Storage.saveMuted(muted.value);
  }
}
