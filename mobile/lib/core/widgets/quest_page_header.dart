import 'package:flutter/material.dart';

/// Shared title plate and typography for the three main game pages.
class QuestPageHeader extends StatelessWidget {
  const QuestPageHeader(
      {super.key,
      required this.title,
      this.subtitle,
      this.unit = 1,
      this.leading,
      this.trailing,
      this.titleKey,
      this.textScaler});

  final String title;
  final String? subtitle;
  final double unit;
  final Widget? leading, trailing;
  final Key? titleKey;
  final TextScaler? textScaler;

  @override
  Widget build(BuildContext context) {
    const ivory = Color(0xffffefd0);
    TextStyle style(double size) => TextStyle(
            inherit: false,
            fontFamily: 'SunlitSerif',
            fontSize: size * unit,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            height: 1.3,
            color: ivory,
            shadows: const [
              Shadow(
                  color: Color(0xcc00152c), blurRadius: 2, offset: Offset(0, 1))
            ]);
    return Stack(children: [
      Positioned.fill(
          child: Image.asset('assets/images/adventure_map_v001/header.png',
              fit: BoxFit.fill, excludeFromSemantics: true)),
      Padding(
          padding:
              EdgeInsets.symmetric(horizontal: 16 * unit, vertical: 9 * unit),
          child: Row(children: [
            SizedBox(
                width: 48 * unit,
                height: 48 * unit,
                child: Center(
                    child: leading ??
                        Image.asset(
                            'assets/images/adventure_map_v003/icon_compass.png',
                            width: 32 * unit,
                            height: 32 * unit,
                            excludeFromSemantics: true))),
            Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Semantics(
                  header: true,
                  child: Text(title,
                      key: titleKey,
                      textAlign: TextAlign.center,
                      textScaler: textScaler,
                      style: style(23))),
              if (subtitle != null)
                Text(subtitle!,
                    textAlign: TextAlign.center,
                    textScaler: textScaler,
                    style: style(11)),
            ])),
            SizedBox(
                width: 48 * unit,
                height: 48 * unit,
                child: Center(child: trailing)),
          ])),
    ]);
  }
}
