import 'package:flutter/material.dart';

import '../utils/audio.dart';
import 'glass_icon_button.dart';

/// Speaker button that toggles sound on/off. The choice is saved, so it is
/// remembered the next time the app starts.
class MuteButton extends StatelessWidget {
  const MuteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = GameAudio.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: audio.muted,
      builder: (context, isMuted, _) => GlassIconButton(
        tooltip: isMuted ? 'Unmute' : 'Mute',
        icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        onPressed: audio.toggleMute,
      ),
    );
  }
}
