import 'package:flutter/material.dart';

import '../../theme/gain_loss_colors.dart';
import '../../utils/number_formatting.dart';
import '../info/info_tooltip_button.dart';

class ComparisonTable extends StatelessWidget {
  const ComparisonTable({super.key, required this.columns, required this.rows});

  final List<({String label, Color color})> columns;
  final List<
    ({
      String label,
      String infoText,
      List<({String text, ValueTrend trend})> values,
    })
  >
  rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gainLossColors = theme.extension<GainLossColors>();
    final valueStyle = theme.textTheme.titleSmall;

    return Table(
      columnWidths: const {0: FlexColumnWidth(2)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            for (final column in columns)
              _Cell(
                child: Column(
                  spacing: 4,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: column.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      column.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(row.label, style: theme.textTheme.bodyMedium),
                  ),
                  InfoTooltipButton(title: row.label, text: row.infoText),
                ],
              ),
              for (final value in row.values)
                _Cell(
                  child: Text(
                    value.text,
                    textAlign: TextAlign.center,
                    style: valueStyle?.copyWith(
                      color: gainLossColors?.colorOf(value.trend),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: child,
    );
  }
}
