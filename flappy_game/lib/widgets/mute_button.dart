import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/audio.dart';

/// Speaker icon that toggles sound on/off. The choice is saved, so it is
/// remembered the next time the app starts.
class MuteButton extends StatelessWidget {
  const MuteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = GameAudio.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: audio.muted,
      builder: (context, isMuted, _) {
        return IconButton(
          tooltip: isMuted ? 'Unmute' : 'Mute',
          onPressed: audio.toggleMute,
          icon: Icon(
            isMuted ? Icons.volume_off : Icons.volume_up,
            color: Colors.white,
            size: 28.r,
            shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
          ),
        );
      },
    );
  }
}
