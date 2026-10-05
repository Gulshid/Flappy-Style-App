import 'dart:ui';

/// Draws [image] repeated horizontally, scaled to [height], scrolled left by
/// [offset] pixels. Shared by the game and the animated menu background.
void drawTiledLayer(
  Canvas canvas,
  Size size,
  Image image,
  Paint paint, {
  required double top,
  required double height,
  required double offset,
}) {
  final scale = height / image.height;
  final tileW = image.width * scale;
  final src =
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

  final shift = offset % tileW;
  var x = -shift - 40; // start a bit left so screen shake never shows a gap
  while (x < size.width + 40) {
    // +1 px overlap between tiles hides hairline seams
    canvas.drawImageRect(image, src, Rect.fromLTWH(x, top, tileW + 1, height), paint);
    x += tileW;
  }
}
