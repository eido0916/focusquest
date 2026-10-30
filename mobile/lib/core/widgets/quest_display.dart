import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Menu routes and focus timers use portrait; battles claim landscape.
/// Releasing the top route restores the orientation of the screen underneath.
class QuestDisplay {
  static final orientation = ValueNotifier(Orientation.portrait);
  static final _claims = <Object, Orientation>{};
  static bool _queued = false;
  static const _channel = MethodChannel('dev.focusquest/display');

  static void claim(Object owner, Orientation mode) {
    _claims[owner] = mode;
    _schedule();
  }

  static void release(Object owner) {
    _claims.remove(owner);
    _schedule();
  }

  static void _schedule() {
    if (_queued) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      final next = _claims.values.lastOrNull ?? Orientation.portrait;
      if (orientation.value == next) return;
      orientation.value = next;
      unawaited(_apply(next));
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  static Future<void> _apply(Orientation mode) async {
    await SystemChrome.setPreferredOrientations(mode == Orientation.portrait
        ? [DeviceOrientation.portraitUp]
        : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      try {
        await _channel.invokeMethod<void>('setOrientation', mode.name);
      } on MissingPluginException {
        // Older runners and widget-test hosts do not implement desktop sizing.
      }
    }
  }
}

class QuestDisplayObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) QuestDisplay.claim(route, Orientation.portrait);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    QuestDisplay.release(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    QuestDisplay.release(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) QuestDisplay.release(oldRoute);
    if (newRoute is PageRoute) {
      QuestDisplay.claim(newRoute, Orientation.portrait);
    }
  }
}

mixin QuestLandscapeState<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    QuestDisplay.claim(this, Orientation.landscape);
  }

  @override
  void dispose() {
    QuestDisplay.release(this);
    super.dispose();
  }
}

class QuestOrientationScope extends StatefulWidget {
  const QuestOrientationScope(
      {super.key,
      required this.child,
      this.orientation = Orientation.landscape});
  final Widget child;
  final Orientation orientation;
  @override
  State<QuestOrientationScope> createState() => _QuestOrientationScopeState();
}

class _QuestOrientationScopeState extends State<QuestOrientationScope> {
  @override
  void initState() {
    super.initState();
    QuestDisplay.claim(this, widget.orientation);
  }

  @override
  void didUpdateWidget(covariant QuestOrientationScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orientation != widget.orientation) {
      QuestDisplay.claim(this, widget.orientation);
    }
  }

  @override
  void dispose() {
    QuestDisplay.release(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Use phone-sized layout units on portrait pages, including on tall desktops.
/// Text, controls and background then share the same display scale.
class QuestAppViewport extends StatelessWidget {
  const QuestAppViewport({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Orientation>(
      valueListenable: QuestDisplay.orientation,
      child: child,
      builder: (context, mode, child) => ColoredBox(
          color: const Color(0xff061b31),
          child: LayoutBuilder(builder: (context, box) {
            final portrait = mode == Orientation.portrait;
            final rotate = !portrait && box.maxHeight > box.maxWidth;
            final availableWidth = rotate ? box.maxHeight : box.maxWidth;
            final availableHeight = rotate ? box.maxWidth : box.maxHeight;
            final width = portrait
                ? (availableWidth > availableHeight
                    ? math.min(availableWidth, availableHeight * 390 / 844)
                    : availableWidth)
                : availableWidth;
            final scale = portrait ? width / 390 : 1.0;
            final size = Size(width / scale, availableHeight / scale);
            final media = MediaQuery.of(context);
            return SizedBox.expand(
                child: RotatedBox(
                    quarterTurns: rotate ? 1 : 0,
                    child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                            key: const Key('quest-display-canvas'),
                            width: size.width,
                            height: size.height,
                            child: MediaQuery(
                                data: media.copyWith(
                                    size: size,
                                    padding: media.padding / scale,
                                    viewPadding: media.viewPadding / scale,
                                    viewInsets: media.viewInsets / scale),
                                child: child!)))));
          })));
}
