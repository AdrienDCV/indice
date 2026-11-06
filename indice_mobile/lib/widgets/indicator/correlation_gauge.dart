import 'package:flutter/material.dart';

import '../animation/reveal_on_scroll_column.dart';

class CorrelationGauge extends StatelessWidget {
  const CorrelationGauge({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final boundStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Column(
      spacing: 4,
      children: [
        SizedBox(
          height: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.surfaceContainerHighest,
                      colorScheme.primaryContainer,
                      colorScheme.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(width: 2, height: 14, color: colorScheme.outline),
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0,
                  end: RevealOnScrollColumn.isRevealed(context)
                      ? value.clamp(-1, 1)
                      : 0,
                ),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, position, marker) =>
                    Align(alignment: Alignment(position, 0), child: marker),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary, width: 4),
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('−1 · Opposés', style: boundStyle),
            Text('0', style: boundStyle),
            Text('1 · Liés', style: boundStyle),
          ],
        ),
      ],
    );
  }
}
