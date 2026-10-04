import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'game/game_assets.dart';
import 'screens/menu_screen.dart';
import 'utils/audio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phase 0: portrait only + full-screen play
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Phase 7: decode every image ONCE before the first frame (no flicker)
  await GameAssets.load();

  // Phase 8: preload sounds + load the saved mute setting.
  // If audio fails, the game simply runs silent.
  await GameAudio.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Same pattern as FitTrack: LayoutBuilder picks the design size,
    // ScreenUtilInit scales everything from it.
    return LayoutBuilder(
      builder: (context, constraints) {
        return ScreenUtilInit(
          designSize: _getDesignSize(constraints.maxWidth),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) {
            return MaterialApp(
              title: 'Flappy Game',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: Colors.lightBlue,
              ),
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.noScaling,
                  ),
                  child: child!,
                );
              },
              home: const MenuScreen(),
            );
          },
        );
      },
    );
  }
}

Size _getDesignSize(double width) {
  if (width < 600) return const Size(360, 690); // phones
  if (width < 1200) return const Size(834, 1194); // tablets
  return const Size(1440, 1024); // large screens
}
