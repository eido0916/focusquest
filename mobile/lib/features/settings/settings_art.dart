import '../../core/widgets/quest_widgets.dart' show QuestNavigation;
import 'package:flutter/material.dart';
import '../../core/widgets/quest_page_header.dart';

const settingsAssetPath = 'assets/images/settings_ui_v002/';
const settingsInk = Color(0xfffffbf0);
const settingsBrown = Color(0xfff5ce76);
const settingsCream = Color(0xffffedb9);

String _iconName(IconData icon) {
  if (icon == Icons.smartphone_rounded) return 'phone';
  if (icon == Icons.grid_view_rounded) return 'overlay';
  if (icon == Icons.cloud_outlined) return 'cloud';
  if (icon == Icons.shield_rounded) return 'shield';
  if (icon == Icons.music_note_rounded) return 'music';
  if (icon == Icons.volume_up_rounded) return 'sound';
  if (icon == Icons.error_rounded) return 'warning';
  return 'chevron';
}

class SettingsIcon extends StatelessWidget {
  const SettingsIcon(this.icon, {super.key, required this.size});
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context) =>
      Image.asset('${settingsAssetPath}icon-${_iconName(icon)}.png',
          width: size, height: size, excludeFromSemantics: true);
}

/// Stretch only the blank middle, preserving the individual corner ornaments.
class SettingsArt extends StatelessWidget {
  const SettingsArt(this.name, {super.key});
  final String name;
  @override
  Widget build(BuildContext context) {
    final dimensions = switch (name) {
      'title' => const Size(660, 154),
      'section' => const Size(840, 100),
      'panel' => const Size(840, 400),
      'button' => const Size(260, 88),
      'back' => const Size(100, 100),
      'notice' => const Size(780, 96),
      _ => const Size(780, 116),
    };
    final border = ['row', 'notice'].contains(name)
        ? 12.0
        : name == 'back'
            ? 30.0
            : 58.0;
    // A power-of-two scale also keeps slice arithmetic exact at small widths.
    const scale = 4.0;
    final verticalBorder = switch (name) {
      'panel' => 62.0,
      'title' => 48.0,
      'section' || 'back' => 28.0,
      'button' => 24.0,
      _ => 12.0,
    };
    return Image.asset('$settingsAssetPath$name.png',
        scale: scale,
        centerSlice: Rect.fromLTRB(
            border / scale,
            verticalBorder / scale,
            (dimensions.width - border) / scale,
            (dimensions.height - verticalBorder) / scale),
        fit: BoxFit.fill,
        excludeFromSemantics: true);
  }
}

class SettingsTitle extends StatelessWidget {
  const SettingsTitle({super.key, required this.unit, this.onBack});
  final double unit;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => SizedBox(
      height:
          (MediaQuery.textScalerOf(context).scale(1) > 1.2 ? 110 : 95) * unit,
      child: Stack(children: [
        Positioned(
            left: 43 * unit,
            right: 38 * unit,
            top: 8 * unit,
            child: QuestPageHeader(
                key: const Key('settings-page-header'),
                title: '設定',
                subtitle: '冒険を、より快適に',
                unit: unit,
                trailing: Icon(Icons.settings_rounded,
                    size: 30 * unit, color: const Color(0xfff5ce78)))),
        Positioned(
            left: -4 * unit,
            top: 0,
            child: Semantics(
                button: true,
                label: 'ホームに戻る',
                child: InkWell(
                    onTap: onBack ?? () => Navigator.maybePop(context),
                    child: SizedBox(
                        width: 45 * unit,
                        height: 45 * unit,
                        child: Stack(alignment: Alignment.center, children: [
                          const Positioned.fill(child: SettingsArt('back')),
                          Image.asset('${settingsAssetPath}icon-back.png',
                              width: 27 * unit, excludeFromSemantics: true),
                        ]))))),
      ]));
}

class SettingsPanel extends StatelessWidget {
  const SettingsPanel(
      {super.key,
      required this.title,
      required this.icon,
      required this.unit,
      required this.child});
  final String title;
  final IconData icon;
  final double unit;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned.fill(child: SettingsArt('panel')),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Stack(children: [
            const Positioned.fill(child: SettingsArt('section')),
            Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 23 * unit, vertical: 10 * unit),
                child: Row(children: [
                  SettingsIcon(icon, size: 24 * unit),
                  SizedBox(width: 13 * unit),
                  Expanded(
                      child: Text(title,
                          style: TextStyle(
                              color: settingsInk,
                              fontSize: 14 * unit,
                              height: 1.3,
                              fontWeight: FontWeight.w600))),
                ])),
          ]),
          Padding(
              padding: EdgeInsets.fromLTRB(
                  17 * unit, 8 * unit, 17 * unit, 12 * unit),
              child: child),
        ]),
      ]);
}

class SettingsRow extends StatelessWidget {
  const SettingsRow(
      {super.key,
      required this.unit,
      required this.child,
      this.notice = false});
  final double unit;
  final Widget child;
  final bool notice;
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: SettingsArt(notice ? 'notice' : 'row')),
        Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 10 * unit, vertical: 6 * unit),
            child: child),
      ]);
}

class SettingsMedallion extends StatelessWidget {
  const SettingsMedallion(
      {super.key, required this.icon, required this.unit, this.blue = false});
  final IconData icon;
  final double unit;
  final bool blue;
  @override
  Widget build(BuildContext context) =>
      Image.asset('${settingsAssetPath}medallion-${_iconName(icon)}.png',
          width: (blue ? 40 : 36) * unit,
          height: (blue ? 40 : 36) * unit,
          excludeFromSemantics: true);
}

class SettingsValueRow extends StatelessWidget {
  const SettingsValueRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value,
      required this.unit});
  final IconData icon;
  final String label, value;
  final double unit;
  @override
  Widget build(BuildContext context) => SettingsRow(
      unit: unit,
      child: Row(children: [
        SettingsMedallion(icon: icon, unit: unit),
        SizedBox(width: 14 * unit),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14 * unit))),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 11 * unit))),
        SizedBox(width: 10 * unit),
        SettingsIcon(Icons.chevron_right_rounded, size: 20 * unit),
      ]));
}

class SettingsSoundRow extends StatelessWidget {
  const SettingsSoundRow(
      {super.key,
      required this.label,
      required this.icon,
      required this.value,
      required this.onChanged,
      required this.unit});
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double unit;
  @override
  Widget build(BuildContext context) => Semantics(
      label: label,
      toggled: value,
      enabled: onChanged != null,
      child: InkWell(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: SettingsRow(
              unit: unit,
              child: Row(children: [
                SizedBox(
                    width: 40 * unit,
                    child: Center(child: SettingsIcon(icon, size: 24 * unit))),
                SizedBox(width: 8 * unit),
                Expanded(
                    child: Text(label, style: TextStyle(fontSize: 15 * unit))),
                SizedBox(width: 8 * unit),
                Opacity(
                    opacity: onChanged == null ? .5 : 1,
                    child: Image.asset(
                        '${settingsAssetPath}toggle-${value ? 'on' : 'off'}.png',
                        width: 51 * unit,
                        height: 30 * unit,
                        excludeFromSemantics: true)),
              ]))));
}

class SettingsArtButton extends StatelessWidget {
  const SettingsArtButton(
      {super.key,
      required this.label,
      required this.unit,
      required this.onTap,
      this.icon,
      this.red = false});
  final String label;
  final double unit;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool red;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      enabled: onTap != null,
      child: Opacity(
          opacity: onTap == null ? .5 : 1,
          child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 44 * unit),
                  child: Stack(alignment: Alignment.center, children: [
                    const Positioned.fill(child: SettingsArt('button')),
                    Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14 * unit, vertical: 12 * unit),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (icon != null)
                                Icon(icon,
                                    size: 17 * unit, color: settingsBrown),
                              Flexible(
                                  child: Text(label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: settingsInk,
                                          fontSize: 13 * unit,
                                          height: 1.2,
                                          fontWeight: FontWeight.w600))),
                              if (!red)
                                SettingsIcon(Icons.chevron_right_rounded,
                                    size: 17 * unit),
                            ])),
                  ])))));
}

/// Compatibility entry for standalone settings previews; the shell and this
/// preview use the same navigation widget and behavior.
class SettingsNavigation extends StatelessWidget {
  const SettingsNavigation({super.key, required this.onSelect});
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) =>
      QuestNavigation(selected: 3, onSelect: onSelect);
}
