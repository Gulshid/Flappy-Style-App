import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'game_text.dart';

/// Big score number at the top of the screen. Only this small widget
/// rebuilds when the score changes, not the whole game screen.
class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({super.key, required this.score});

  final ValueListenable<int> score;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: score,
      builder: (context, value, _) => GameText('$value', fontSize: 52),
    );
  }
}
