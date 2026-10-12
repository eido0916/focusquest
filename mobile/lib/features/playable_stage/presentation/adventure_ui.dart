import 'package:flutter/material.dart';
import '../../../core/widgets/sunlit_widgets.dart';

/// Presentation only: the battle canvas keeps its original pixel sampling.
class AdventureUi extends StatelessWidget {
  const AdventureUi({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
        data: base.copyWith(
            scaffoldBackgroundColor: sunlitInk,
            textTheme: base.textTheme.apply(
                fontFamily: 'SunlitSerif',
                bodyColor: const Color(0xfffff3d9),
                displayColor: const Color(0xfffff3d9)),
            colorScheme: base.colorScheme.copyWith(
                primary: sunlitGold,
                onPrimary: sunlitInk,
                surface: sunlitInk,
                onSurface: const Color(0xfffff3d9)),
            iconTheme: const IconThemeData(color: sunlitGold),
            chipTheme: base.chipTheme.copyWith(
                backgroundColor: sunlitInk,
                selectedColor: sunlitGold,
                side: const BorderSide(color: sunlitGold),
                labelStyle: const TextStyle(
                    fontFamily: 'SunlitSerif', color: Color(0xfffff3d9)),
                secondaryLabelStyle: const TextStyle(
                    fontFamily: 'SunlitSerif', color: sunlitInk),
                checkmarkColor: sunlitInk),
            appBarTheme: const AppBarTheme(
                backgroundColor: sunlitInk,
                foregroundColor: sunlitGold,
                surfaceTintColor: Colors.transparent,
                centerTitle: false,
                titleTextStyle: TextStyle(
                    fontFamily: 'SunlitSerif',
                    fontSize: 18,
                    color: Color(0xfffff3d9),
                    fontWeight: FontWeight.bold))),
        child: child);
  }
}

AppBar adventureAppBar(String title,
        {List<Widget>? actions, bool automaticallyImplyLeading = true}) =>
    AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: actions,
        flexibleSpace: const IgnorePointer(
            child: SafeArea(
                child: SunlitFrame(
                    compact: true,
                    padding: EdgeInsets.zero,
                    child: SizedBox.expand()))));

class AdventureBackdrop extends StatelessWidget {
  const AdventureBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/ui/sunlit_kingdom.png',
            fit: BoxFit.cover, alignment: Alignment.topCenter),
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x55071c3c), Color(0xf5071c3c)]))),
        child,
      ]);
}
