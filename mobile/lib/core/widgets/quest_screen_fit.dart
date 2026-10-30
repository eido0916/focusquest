import 'package:flutter/material.dart';

/// Keeps a complete page inside the available safe area, without a scroll
/// gesture. The existing composition grows naturally, then scales down only
/// when its content is taller than the screen (including keyboard insets).
class QuestScreenFit extends StatelessWidget {
  const QuestScreenFit({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final content = SizedBox(
            width: box.maxWidth,
            child: Padding(padding: padding, child: child));
        if (!box.hasBoundedHeight) return content;
        return ClipRect(
            child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: content));
      });
}
