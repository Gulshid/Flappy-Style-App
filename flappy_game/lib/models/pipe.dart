import 'dart:ui';

/// One pair of pipes (top + bottom) with a gap between them.
///
/// Units:
///  - [x]          centre of the pipe, in screen WIDTHS  (0 = left, 1 = right)
///  - [gapCenterY] centre of the gap, in screen HEIGHTS  (0 = top, 1 = bottom)
///  - [gapSize]    height of the gap, in screen HEIGHTS
///
/// The pipe's pixel width is not stored here: it comes from ScreenUtil in the
/// UI layer and is passed in as [pipeWidth] when rects are needed.
class Pipe {
  double x;
  final double gapCenterY;
  final double gapSize;

  Pipe({
    required this.x,
    required this.gapCenterY,
    required this.gapSize,
  });

  double left(Size s, double pipeWidth) => x * s.width - pipeWidth / 2;
  double right(Size s, double pipeWidth) => x * s.width + pipeWidth / 2;

  double gapTop(Size s) => (gapCenterY - gapSize / 2) * s.height;
  double gapBottom(Size s) => (gapCenterY + gapSize / 2) * s.height;

  /// Pipe above the gap (from the top of the screen down to the gap).
  Rect topRect(Size s, double pipeWidth) =>
      Rect.fromLTRB(left(s, pipeWidth), 0, right(s, pipeWidth), gapTop(s));

  /// Pipe below the gap (from the gap down to the bottom of the screen).
  Rect bottomRect(Size s, double pipeWidth) => Rect.fromLTRB(
      left(s, pipeWidth), gapBottom(s), right(s, pipeWidth), s.height);
}
