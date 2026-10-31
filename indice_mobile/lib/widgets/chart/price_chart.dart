import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PriceChart extends StatefulWidget {
  const PriceChart({
    super.key,
    required this.series,
    required this.tooltipLabel,
    required this.axisLabel,
  });

  final List<
    ({String label, Color color, List<({DateTime date, double value})> points})
  >
  series;
  final String Function(int index) tooltipLabel;
  final String Function(double value) axisLabel;

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  static const _pointsPerVisibleWindow = 252;
  static const _leftTitlesWidth = 48.0;
  static const _bottomTitlesHeight = 28.0;

  TransformationController? _transformationController;

  List<({DateTime date, double value})> get _dates =>
      widget.series.first.points;

  double get _initialScale => max(1, _dates.length / _pointsPerVisibleWindow);

  @override
  void dispose() {
    _transformationController?.dispose();
    super.dispose();
  }

  TransformationController _transformationControllerFor(double chartWidth) {
    return _transformationController ??= TransformationController(
      Matrix4.identity()
        ..translateByDouble(-(_initialScale - 1) * chartWidth, 0, 0, 1)
        ..scaleByDouble(_initialScale, _initialScale, 1, 1),
    );
  }

  bool _startsNewYear(int index) =>
      index == 0 || _dates[index].date.year != _dates[index - 1].date.year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Column(
      spacing: 8,
      children: [
        SizedBox(
          height: 220,
          child: LayoutBuilder(
            builder: (context, constraints) => LineChart(
              LineChartData(
                minX: 0,
                maxX: (_dates.length - 1).toDouble(),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(drawVerticalLine: false),
                lineBarsData: [
                  for (final series in widget.series)
                    LineChartBarData(
                      spots: [
                        for (final (index, point) in series.points.indexed)
                          FlSpot(index.toDouble(), point.value),
                      ],
                      color: series.color,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                ],
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: _leftTitlesWidth,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(widget.axisLabel(value), style: titleStyle),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: _bottomTitlesHeight,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (value != index || !_startsNewYear(index)) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${_dates[index].date.year}',
                            style: titleStyle,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    getTooltipColor: (_) => colorScheme.inverseSurface,
                    getTooltipItems: (touchedSpots) => [
                      for (final (index, spot) in touchedSpots.indexed)
                        index == 0
                            ? LineTooltipItem(
                                widget.tooltipLabel(spot.x.toInt()),
                                theme.textTheme.bodySmall!.copyWith(
                                  color: colorScheme.onInverseSurface,
                                ),
                              )
                            : null,
                    ],
                  ),
                ),
              ),
              transformationConfig: FlTransformationConfig(
                scaleAxis: FlScaleAxis.horizontal,
                maxScale: _initialScale,
                scaleEnabled: false,
                transformationController: _transformationControllerFor(
                  constraints.maxWidth - _leftTitlesWidth,
                ),
              ),
            ),
          ),
        ),
        if (widget.series.length > 1)
          Wrap(
            spacing: 16,
            children: [
              for (final series in widget.series)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: series.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(series.label, style: theme.textTheme.bodySmall),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}
