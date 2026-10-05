import 'dart:ui';

/// Awarded at the end of a round, based on the score.
enum Medal { none, bronze, silver, gold, platinum }

Medal medalForScore(int score) {
  if (score >= Medal.platinum.threshold) return Medal.platinum;
  if (score >= Medal.gold.threshold) return Medal.gold;
  if (score >= Medal.silver.threshold) return Medal.silver;
  if (score >= Medal.bronze.threshold) return Medal.bronze;
  return Medal.none;
}

extension MedalInfo on Medal {
  int get threshold => switch (this) {
        Medal.none => 0,
        Medal.bronze => 10,
        Medal.silver => 20,
        Medal.gold => 30,
        Medal.platinum => 40,
      };

  String get label => switch (this) {
        Medal.none => 'No medal',
        Medal.bronze => 'Bronze',
        Medal.silver => 'Silver',
        Medal.gold => 'Gold',
        Medal.platinum => 'Platinum',
      };

  /// The medal after this one (null when this is the best).
  Medal? get next => switch (this) {
        Medal.none => Medal.bronze,
        Medal.bronze => Medal.silver,
        Medal.silver => Medal.gold,
        Medal.gold => Medal.platinum,
        Medal.platinum => null,
      };

  Color get light => switch (this) {
        Medal.none => const Color(0x33FFFFFF),
        Medal.bronze => const Color(0xFFE9A15F),
        Medal.silver => const Color(0xFFF2F5F8),
        Medal.gold => const Color(0xFFFFE27A),
        Medal.platinum => const Color(0xFFD2F7FF),
      };

  Color get dark => switch (this) {
        Medal.none => const Color(0x33FFFFFF),
        Medal.bronze => const Color(0xFF9A5A1B),
        Medal.silver => const Color(0xFF8F9AA8),
        Medal.gold => const Color(0xFFC79100),
        Medal.platinum => const Color(0xFF4FA3C7),
      };
}
