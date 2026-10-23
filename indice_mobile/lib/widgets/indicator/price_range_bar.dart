import 'package:flutter/material.dart';

class PriceRangeBar extends StatelessWidget {
  const PriceRangeBar({
    super.key,
    required this.low,
    required this.high,
    required this.position,
  });

  final String low;
  final String high;
  final double position;

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
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Align(
                alignment: Alignment(position.clamp(0, 1) * 2 - 1, 0),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          spacing: 16,
          children: [
            Expanded(child: Text('Plus bas : $low', style: boundStyle)),
            Expanded(
              child: Text(
                'Plus haut : $high',
                style: boundStyle,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
