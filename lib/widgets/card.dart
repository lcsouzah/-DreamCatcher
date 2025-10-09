import 'dart:ui';

import 'package:flutter/material.dart';

import '../themes/app_theme.dart';

class DreamCard extends StatelessWidget {
  const DreamCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DreamCardTheme cardTheme =
        theme.extension<DreamCardTheme>() ?? DreamCardTheme.fallback;

    return ClipRRect(
      borderRadius: cardTheme.borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: cardTheme.blurSigma,
          sigmaY: cardTheme.blurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: cardTheme.borderRadius,
            gradient: cardTheme.backgroundGradient,
            border: Border.all(color: cardTheme.borderColor),
            boxShadow: cardTheme.shadow,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: cardTheme.borderRadius,
              color: cardTheme.overlayColor,
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}