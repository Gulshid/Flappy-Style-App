import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/difficulty.dart';
import '../models/skin.dart';
import '../utils/audio.dart';
import '../utils/settings.dart';
import '../utils/stats.dart';
import '../utils/theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_switch.dart';
import '../widgets/bird_sprite.dart';
import '../widgets/game_text.dart';
import '../widgets/glass_card.dart';
import '../widgets/screen_frame.dart';

/// Sound, gameplay, bird colour and data. Everything is saved immediately and
/// remembered the next time the app starts.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = GameAudio.instance;
    final settings = GameSettings.instance;

    return ScreenFrame(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------- Sound
          const _SectionTitle('Sound'),
          _Group(children: [
            ValueListenableBuilder<bool>(
              valueListenable: audio.muted,
              builder: (context, muted, _) => _SettingRow(
                icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                title: 'Sound effects',
                trailing: AppSwitch(
                  value: !muted,
                  onChanged: (_) => audio.toggleMute(),
                ),
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: audio.volume,
              builder: (context, volume, _) => _SettingRow(
                icon: Icons.graphic_eq_rounded,
                title: 'Volume',
                below: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6.h,
                    activeTrackColor: AppColors.amber,
                    inactiveTrackColor: AppColors.alpha(Colors.white, 0.25),
                    thumbColor: AppColors.amberLight,
                    overlayColor: AppColors.alpha(AppColors.amber, 0.2),
                    thumbShape:
                        RoundSliderThumbShape(enabledThumbRadius: 10.r),
                  ),
                  child: Slider(
                    value: volume,
                    onChanged: (v) => audio.setVolume(v),
                    onChangeEnd: (v) {
                      audio.setVolume(v, save: true);
                      audio.play(Sfx.score); // let the player hear the level
                    },
                  ),
                ),
              ),
            ),
          ]),

          // --------------------------------------------------- Gameplay
          const _SectionTitle('Gameplay'),
          ValueListenableBuilder<Difficulty>(
            valueListenable: settings.difficulty,
            builder: (context, current, _) => Column(
              children: [
                for (final d in Difficulty.values)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: _DifficultyTile(
                      difficulty: d,
                      selected: d == current,
                      onTap: () => settings.setDifficulty(d),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          _Group(children: [
            ValueListenableBuilder<bool>(
              valueListenable: settings.vibration,
              builder: (context, on, _) => _SettingRow(
                icon: Icons.vibration,
                title: 'Vibration',
                subtitle: 'A buzz when you crash',
                trailing: AppSwitch(
                  value: on,
                  onChanged: (value) {
                    settings.setVibration(value);
                    // Small buzz so you can feel it is on
                    if (value) HapticFeedback.mediumImpact();
                  },
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: settings.dynamicSky,
              builder: (context, on, _) => _SettingRow(
                icon: Icons.nights_stay_rounded,
                title: 'Changing sky',
                subtitle: 'Day turns to night as you score',
                trailing: AppSwitch(
                  value: on,
                  onChanged: settings.setDynamicSky,
                ),
              ),
            ),
          ]),

          // ------------------------------------------------------- Bird
          const _SectionTitle('Bird colour'),
          ValueListenableBuilder<BirdSkin>(
            valueListenable: settings.skin,
            builder: (context, current, _) => Row(
              children: [
                for (final s in BirdSkin.values)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: s == BirdSkin.values.last ? 0 : 8.w),
                      child: _SkinTile(
                        skin: s,
                        selected: s == current,
                        onTap: () => settings.setSkin(s),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ------------------------------------------------------ Advanced
          const _SectionTitle('Advanced'),
          _Group(children: [
            ValueListenableBuilder<bool>(
              valueListenable: settings.showHitboxes,
              builder: (context, on, _) => _SettingRow(
                icon: Icons.crop_square_rounded,
                title: 'Show hitboxes',
                subtitle: 'Outlines what counts as a crash',
                trailing: AppSwitch(
                  value: on,
                  onChanged: settings.setShowHitboxes,
                ),
              ),
            ),
            _SettingRow(
              icon: Icons.delete_outline_rounded,
              title: 'Reset progress',
              subtitle: 'Clears scores and statistics',
              trailing: SizedBox(
                width: 92.w,
                child: AppButton(
                  label: 'Reset',
                  style: AppButtonStyle.danger,
                  height: 38,
                  fontSize: 14,
                  onPressed: () => _confirmReset(context),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: AppColors.alpha(Colors.white, 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reset progress?', style: appStyle(22, weight: FontWeight.w900)),
              SizedBox(height: 10.h),
              Text(
                'This clears your best scores and statistics. Your settings are kept.',
                textAlign: TextAlign.center,
                style: appStyle(15,
                    color: Colors.white70, weight: FontWeight.w500, height: 1.35),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      style: AppButtonStyle.secondary,
                      height: 46,
                      fontSize: 16,
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: AppButton(
                      label: 'Reset',
                      style: AppButtonStyle.danger,
                      height: 46,
                      fontSize: 16,
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    await PlayerStats.instance.reset();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress reset')),
    );
  }
}

// ---------------------------------------------------------------- Pieces

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h, bottom: 10.h, left: 4.w),
      child: GameText(text, fontSize: 18),
    );
  }
}

/// A card holding several rows separated by thin dividers.
class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(height: 1, color: AppColors.alpha(Colors.white, 0.14)));
      }
      rows.add(children[i]);
    }
    return GlassCard(
      blur: 10,
      radius: 22,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(children: rows),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.below,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Full-width content under the title (e.g. a slider).
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: AppColors.alpha(Colors.white, 0.14),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: AppColors.amberLight, size: 22.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: appStyle(16, weight: FontWeight.w800)),
                    if (subtitle != null)
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Text(subtitle!,
                            style: appStyle(12.5,
                                color: Colors.white70,
                                weight: FontWeight.w500)),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (below != null) below!,
        ],
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final Difficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: selected
                ? AppColors.alpha(AppColors.amber, 0.22)
                : AppColors.alpha(AppColors.ink, 0.42),
            border: Border.all(
              color: selected
                  ? AppColors.amber
                  : AppColors.alpha(Colors.white, 0.2),
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(difficulty.label,
                        style: appStyle(17, weight: FontWeight.w900)),
                    SizedBox(height: 2.h),
                    Text(difficulty.description,
                        style: appStyle(13,
                            color: Colors.white70, weight: FontWeight.w500)),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    color: AppColors.amber, size: 24.r),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkinTile extends StatelessWidget {
  const _SkinTile({
    required this.skin,
    required this.selected,
    required this.onTap,
  });

  final BirdSkin skin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: skin.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: selected
                ? AppColors.alpha(AppColors.amber, 0.22)
                : AppColors.alpha(AppColors.ink, 0.42),
            border: Border.all(
              color: selected
                  ? AppColors.amber
                  : AppColors.alpha(Colors.white, 0.2),
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Column(
            children: [
              BirdSprite(size: 46.r, skin: skin, animate: false),
              SizedBox(height: 6.h),
              Text(skin.label, style: appStyle(12, weight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
