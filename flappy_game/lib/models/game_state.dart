/// The flow of one round:
///   ready    -> bird floats, waiting for the first tap
///   playing  -> normal gameplay
///   gameOver -> pipes frozen, bird falls, Game Over panel is shown
enum GameState { ready, playing, gameOver }
