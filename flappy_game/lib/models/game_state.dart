/// The flow of one round:
///   ready    -> bird floats, waiting for the first tap
///   playing  -> normal gameplay
///   gameOver -> pipes frozen, bird falls, Game Over panel is shown
enum GameState { ready, playing, gameOver }

/// Things that happen during a round that the UI may want to react to
/// (sound, vibration). The controller only announces them; it never plays
/// anything itself.
///   flap     -> the bird flapped (tap while playing, or the first tap)
///   score    -> the bird passed a pipe
///   hit      -> the bird crashed (pipe, ground or ceiling)
///   gameOver -> shortly after the crash, when the round is really over
enum GameEvent { flap, score, hit, gameOver }
