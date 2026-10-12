import 'package:flutter/material.dart';
import '../../core/widgets/sunlit_widgets.dart';
import '../../core/widgets/quest_widgets.dart';

const settingsAssetPath = 'assets/images/settings_ui_v001/';
const settingsInk = Color(0xff2c170b);
const settingsBrown = Color(0xff966b2b);
const settingsCream = Color(0xffffedb9);

class SettingsArt extends StatelessWidget {
  const SettingsArt(this.name, {super.key, this.slice});
  final String name;
  final Rect? slice;
  @override
  Widget build(BuildContext context) =>
      Image.asset('$settingsAssetPath$name.png',
          fit: BoxFit.fill,
          scale: 3,
          centerSlice: slice,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true);
}

class SettingsTitle extends StatelessWidget {
  const SettingsTitle({super.key, required this.unit});
  final double unit;
  @override
  Widget build(BuildContext context) => SizedBox(
      height:
          (92 + (MediaQuery.textScalerOf(context).scale(1) - 1) * 45) * unit,
      child: Stack(fit: StackFit.expand, children: [
        const SettingsArt('title_banner'),
        Padding(
            padding:
                EdgeInsets.fromLTRB(80 * unit, 24 * unit, 42 * unit, 12 * unit),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('設定',
                  style: TextStyle(
                      color: settingsCream,
                      fontFamily: 'SunlitSerif',
                      fontSize: 26 * unit,
                      fontWeight: FontWeight.bold,
                      height: 1.05,
                      shadows: const [
                        Shadow(color: Color(0xff001c39), offset: Offset(1, 2))
                      ])),
              SizedBox(height: 4 * unit),
              SettingsRule(unit: unit, blue: true),
              Text('冒険を、より快適に',
                  style: TextStyle(
                      color: settingsCream,
                      fontFamily: 'SunlitSerif',
                      fontSize: 10 * unit,
                      fontWeight: FontWeight.bold)),
            ])),
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
        const Positioned.fill(
            child: SettingsArt('parchment_panel',
                slice: Rect.fromLTRB(80, 80, 944, 560))),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Stack(children: [
            const Positioned.fill(
                child: SettingsArt('section_header',
                    slice: Rect.fromLTRB(110, 38, 914, 90))),
            Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 22 * unit, vertical: 5 * unit),
                child: Row(children: [
                  Icon(icon, color: settingsCream, size: 22 * unit),
                  SizedBox(width: 10 * unit),
                  Flexible(
                      child: Text(title,
                          style: TextStyle(
                              color: settingsCream,
                              fontFamily: 'SunlitSerif',
                              fontSize: 15 * unit,
                              fontWeight: FontWeight.bold))),
                  SizedBox(width: 10 * unit),
                  const Icon(Icons.auto_awesome, color: sunlitGold, size: 14),
                ])),
          ]),
          Padding(
              padding: EdgeInsets.fromLTRB(
                  24 * unit, 8 * unit, 22 * unit, 14 * unit),
              child: child),
        ]),
      ]);
}

class SettingsMedallion extends StatelessWidget {
  const SettingsMedallion(
      {super.key, required this.icon, required this.unit, this.blue = false});
  final IconData icon;
  final double unit;
  final bool blue;
  @override
  Widget build(BuildContext context) => Container(
      width: 36 * unit,
      height: 36 * unit,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xffffefbc), Color(0xffefd083)]),
          border: Border.all(color: const Color(0xffcfab62)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x99fff9dd), offset: Offset(0, -1), blurRadius: 1)
          ]),
      child: Icon(icon,
          size: 24 * unit,
          color: blue ? const Color(0xff095081) : settingsBrown));
}

class SettingsValueRow extends StatelessWidget {
  const SettingsValueRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value,
      required this.unit});
  final IconData icon;
  final String label;
  final String value;
  final double unit;
  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.symmetric(vertical: 1 * unit),
      child: Row(children: [
        SettingsMedallion(icon: icon, unit: unit),
        SizedBox(width: 14 * unit),
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'SunlitSerif',
                    fontSize: 13 * unit,
                    fontWeight: FontWeight.bold))),
        ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 110 * unit),
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 10.5 * unit))),
        Icon(Icons.chevron_right_rounded,
            color: settingsBrown, size: 20 * unit),
      ]));
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
          opacity: onTap == null ? .55 : 1,
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Stack(children: [
                        Positioned.fill(
                            child: SettingsArt(
                                red ? 'reset_button' : 'blue_button',
                                slice: const Rect.fromLTRB(80, 54, 432, 74))),
                        Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12 * unit, vertical: 11 * unit),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (icon != null) ...[
                                    Icon(icon,
                                        color: settingsCream, size: 19 * unit),
                                    SizedBox(width: 6 * unit)
                                  ],
                                  Flexible(
                                      child: Text(label,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: settingsCream,
                                              fontSize: 12 * unit,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'SunlitSerif'))),
                                  if (!red)
                                    Icon(Icons.chevron_right_rounded,
                                        color: sunlitGold, size: 18 * unit),
                                ])),
                      ]))))));
}

class SettingsRule extends StatelessWidget {
  const SettingsRule({super.key, required this.unit, this.blue = false});
  final double unit;
  final bool blue;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(Icons.auto_awesome,
            size: 4 * unit, color: blue ? sunlitGold : const Color(0xffc6a15c)),
        Expanded(
            child: Container(
                height: .6,
                color: blue ? sunlitGold : const Color(0xffceb171))),
        Icon(Icons.auto_awesome,
            size: 5 * unit, color: blue ? sunlitGold : const Color(0xffc6a15c)),
      ]);
}

class SettingsNavigation extends StatelessWidget {
  const SettingsNavigation({super.key, required this.onSelect});
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) =>
      QuestNavigation(selected: 3, onSelect: onSelect);
}
