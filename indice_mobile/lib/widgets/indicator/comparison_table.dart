import 'package:flutter/material.dart';

import '../../theme/gain_loss_colors.dart';
import '../../utils/number_formatting.dart';
import '../info/info_tooltip_button.dart';

class ComparisonTableRow<T> {
  const ComparisonTableRow({
    required this.label,
    required this.infoText,
    required this.value,
    this.trend,
  });

  final String label;
  final String infoText;
  final String Function(T item) value;
  final ValueTrend Function(T item)? trend;
}

class ComparisonTable<T> extends StatelessWidget {
  const ComparisonTable({super.key, required this.columns, required this.rows});

  final List<({String label, Color color, T item})> columns;
  final List<ComparisonTableRow<T>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              _ColumnHeader(label: column.label, color: column.color),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              _LabelCell(label: row.label, infoText: row.infoText),
              for (final column in columns)
                _ValueCell(
                  text: row.value(column.item),
                  trend: row.trend?.call(column.item) ?? ValueTrend.neutral,
                ),
            ],
          ),
      ],
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Cell(
      child: Column(
        spacing: 4,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _LabelCell extends StatelessWidget {
  const _LabelCell({required this.label, required this.infoText});

  final String label;
  final String infoText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        InfoTooltipButton(title: label, text: infoText),
      ],
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({required this.text, required this.trend});

  final String text;
  final ValueTrend trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gainLossColors = theme.extension<GainLossColors>();

    return _Cell(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleSmall?.copyWith(
          color: gainLossColors?.colorOf(trend),
        ),
      ),
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
