import 'package:flutter/material.dart';

class EtfSlotField extends StatelessWidget {
  const EtfSlotField({
    super.key,
    required this.label,
    required this.color,
    required this.ticker,
    required this.onTap,
  });

  final String label;
  final Color color;
  final String? ticker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ticker = this.ticker;
    final isLocked = onTap == null;

    return Material(
      color: isLocked
          ? colorScheme.surfaceContainer
          : colorScheme.surfaceContainerHigh,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            spacing: 14,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      ticker ?? 'Choisir un ETF',
                      style: ticker == null
                          ? theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            )
                          : theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                  ],
                ),
              ),
              if (!isLocked)
                Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
