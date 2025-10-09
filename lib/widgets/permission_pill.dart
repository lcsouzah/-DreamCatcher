import 'package:flutter/material.dart';

import '../themes/app_theme.dart';

class PermissionPill extends StatelessWidget {
  const PermissionPill({
    super.key,
    required this.label,
    required this.status,
    required this.statusColor,
    this.onPressed,
    this.actionLabel,
  });

  final String label;
  final String status;
  final Color statusColor;
  final VoidCallback? onPressed;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final DreamCardTheme cardTheme =
        theme.extension<DreamCardTheme>() ?? DreamCardTheme.fallback;
    final DreamGradients gradients =
        theme.extension<DreamGradients>() ?? DreamGradients.fallback;
    final ColorScheme colors = theme.colorScheme;

    return ClipRRect(
      borderRadius: cardTheme.borderRadius,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: cardTheme.borderRadius,
          gradient: gradients.cardHighlight,
          border: Border.all(color: cardTheme.borderColor),
          boxShadow: cardTheme.shadow,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: cardTheme.borderRadius,
            color: cardTheme.overlayColor,
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        status,
                        style: textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onPressed != null && actionLabel != null)
                TextButton(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    textStyle: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}