import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Every colour the UI uses lives here, so the look can be changed in one place.
class AppColors {
  AppColors._();

  // Sky (matches the "day" palette in game/sky_palette.dart)
  static const Color skyTop = Color(0xFF4EC0CA);
  static const Color skyBottom = Color(0xFFB8E8F0);

  // Surfaces
  static const Color ink = Color(0xFF0E2233);

  // Accents
  static const Color amber = Color(0xFFFFB300);
  static const Color amberLight = Color(0xFFFFD54F);
  static const Color onAmber = Color(0xFF3B2300);
  static const Color mint = Color(0xFF2EC4A6);
  static const Color coral = Color(0xFFFF6B6B);

  /// [c] with the given opacity (0..1). Works on every Flutter version.
  static Color alpha(Color c, double opacity) =>
      c.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
}

/// Material 3 theme. Set [fontFamily] (and declare the font in pubspec.yaml)
/// to change the typeface everywhere at once.
class AppTheme {
  AppTheme._();

  static const String? fontFamily = null;

  static ThemeData get data => ThemeData(
        useMaterial3: true,
        fontFamily: fontFamily,
        colorSchemeSeed: AppColors.amber,
        scaffoldBackgroundColor: AppColors.skyTop,
        splashFactory: NoSplash.splashFactory,
      );
}

/// Text style helper: [size] is in design pixels and is scaled with ScreenUtil.
TextStyle appStyle(
  double size, {
  Color color = Colors.white,
  FontWeight weight = FontWeight.w700,
  double spacing = 0,
  double? height,
}) =>
    TextStyle(
      fontSize: size.sp,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
      decoration: TextDecoration.none,
    );

/// Screen transition: a soft fade with a small upward slide.
class AppRoute<T> extends PageRouteBuilder<T> {
  AppRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: curved.drive(
                  Tween<Offset>(
                      begin: const Offset(0, 0.04), end: Offset.zero),
                ),
                child: child,
              ),
            );
          },
        );
}
