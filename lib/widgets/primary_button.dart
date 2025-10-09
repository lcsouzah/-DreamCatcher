import 'package:flutter/material.dart';

import '../themes/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final DreamButtonTheme buttonTheme =
        theme.extension<DreamButtonTheme>() ?? DreamButtonTheme.fallback;
    final bool isEnabled = onPressed != null && !isLoading;
    final Gradient gradient =
    isEnabled ? buttonTheme.primaryGradient : buttonTheme.disabledGradient;
    final List<BoxShadow> shadow = isEnabled ? buttonTheme.glow : <BoxShadow>[];

    final Widget child = isLoading
        ? SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor:
        AlwaysStoppedAnimation<Color>(buttonTheme.foregroundColor),
      ),
    )
        : Text(
      label,
      style: textTheme.labelLarge?.copyWith(
        color: buttonTheme.foregroundColor,
        fontWeight: FontWeight.w700,
      ),
    );

    final Widget button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: buttonTheme.borderRadius,
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: buttonTheme.borderRadius,
        child: TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            padding: buttonTheme.padding,
            foregroundColor: buttonTheme.foregroundColor,
            disabledForegroundColor: buttonTheme.foregroundColor.withOpacity(0.6),
            backgroundColor: Colors.transparent,
            textStyle: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );

    if (!expanded) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}