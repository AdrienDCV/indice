import 'package:flutter/material.dart';

import '../../theme/gain_loss_colors.dart';
import '../../utils/number_formatting.dart';

class ReturnsTable extends StatelessWidget {
  const ReturnsTable({super.key, required this.returns});

  final List<({String period, String value, ValueTrend trend})> returns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gainLossColors = theme.extension<GainLossColors>();

    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      children: [
        TableRow(
          children: [
            for (final row in returns)
              _Cell(
                text: row.period,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        TableRow(
          children: [
            for (final row in returns)
              _Cell(
                text: row.value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: gainLossColors?.colorOf(row.trend),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }
}
