import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PriceChart extends StatefulWidget {
  const PriceChart({
    super.key,
    required this.points,
    required this.tooltipLabel,
  });

  final List<({DateTime date, double value})> points;
  final String Function(int index) tooltipLabel;

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  static const _pointsPerVisibleWindow = 252;
  static const _leftTitlesWidth = 48.0;
  static const _bottomTitlesHeight = 28.0;

  TransformationController? _transformationController;

  double get _initialScale =>
      max(1, widget.points.length / _pointsPerVisibleWindow);

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
      index == 0 ||
      widget.points[index].date.year != widget.points[index - 1].date.year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return SizedBox(
      height: 220,
      child: LayoutBuilder(
        builder: (context, constraints) => LineChart(
          LineChartData(
            minX: 0,
            maxX: (widget.points.length - 1).toDouble(),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(drawVerticalLine: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (final (index, point) in widget.points.indexed)
                    FlSpot(index.toDouble(), point.value),
                ],
                color: colorScheme.primary,
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
                    child: Text(value.toStringAsFixed(0), style: titleStyle),
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
                        '${widget.points[index].date.year}',
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
                  for (final spot in touchedSpots)
                    LineTooltipItem(
                      widget.tooltipLabel(spot.x.toInt()),
                      theme.textTheme.bodySmall!.copyWith(
                        color: colorScheme.onInverseSurface,
                      ),
                    ),
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
    );
  }
}
