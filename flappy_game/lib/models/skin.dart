import 'dart:math';
import 'dart:ui';

/// Bird colour variants. They re-colour the existing bird sprite with a colour
/// filter, so no extra image files are needed.
enum BirdSkin { classic, ocean, blossom, shadow }

extension BirdSkinInfo on BirdSkin {
  String get label => switch (this) {
        BirdSkin.classic => 'Classic',
        BirdSkin.ocean => 'Ocean',
        BirdSkin.blossom => 'Blossom',
        BirdSkin.shadow => 'Shadow',
      };

  /// null = draw the sprite unchanged.
  ColorFilter? get filter => switch (this) {
        BirdSkin.classic => null,
        BirdSkin.ocean => ColorFilter.matrix(_hueRotate(150)),
        BirdSkin.blossom => ColorFilter.matrix(_hueRotate(285)),
        BirdSkin.shadow => const ColorFilter.matrix(_shadowMatrix),
      };
}

// Darker, desaturated, slightly blue.
const List<double> _shadowMatrix = <double>[
  0.12, 0.39, 0.04, 0, 0, //
  0.12, 0.39, 0.04, 0, 0, //
  0.14, 0.45, 0.05, 0, 10, //
  0, 0, 0, 1, 0,
];

/// Standard hue-rotation colour matrix.
List<double> _hueRotate(double degrees) {
  final r = degrees * pi / 180;
  final c = cos(r);
  final s = sin(r);
  return <double>[
    0.213 + c * 0.787 - s * 0.213, 0.715 - c * 0.715 - s * 0.715,
    0.072 - c * 0.072 + s * 0.928, 0, 0, //
    0.213 - c * 0.213 + s * 0.143, 0.715 + c * 0.285 + s * 0.140,
    0.072 - c * 0.072 - s * 0.283, 0, 0, //
    0.213 - c * 0.213 - s * 0.787, 0.715 - c * 0.715 + s * 0.715,
    0.072 + c * 0.928 + s * 0.072, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}
