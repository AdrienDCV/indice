import 'dart:math';

typedef AxisScale = ({double min, double max, double interval});

const _targetIntervalCount = 5;
const _roundMultipliers = [1, 2, 5, 10];

AxisScale axisScaleOf(Iterable<double> values) {
  final lowest = values.reduce(min);
  final highest = values.reduce(max);
  final interval = _roundInterval(
    highest > lowest
        ? (highest - lowest) / _targetIntervalCount
        : max(highest.abs() / 10, 1),
  );
  final lower = (lowest / interval).floor() * interval;
  final upper = (highest / interval).ceil() * interval;
  return (
    min: lower,
    max: upper > lower ? upper : lower + interval,
    interval: interval,
  );
}

int fractionDigitsOf(double interval) =>
    max(0, -(_log10(interval) + 1e-9).floor());

double _roundInterval(double rawInterval) {
  final power = pow(10, _log10(rawInterval).floor()).toDouble();
  final multiplier = _roundMultipliers.firstWhere(
    (multiplier) => rawInterval / power <= multiplier,
    orElse: () => _roundMultipliers.last,
  );
  return multiplier * power;
}

double _log10(double value) => log(value) / ln10;
