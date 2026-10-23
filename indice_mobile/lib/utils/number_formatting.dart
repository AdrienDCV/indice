const _missingValue = '—';
const _nonBreakingSpace = '\u00A0';

extension NumberFormatting on double? {
  String toFrenchPercent({int fractionDigits = 2}) {
    final value = this;
    if (value == null) return _missingValue;
    return '${_frenchDecimal(value * 100, fractionDigits)}$_nonBreakingSpace%';
  }

  String toFrenchSignedPercent({int fractionDigits = 2}) {
    final value = this;
    if (value == null) return _missingValue;
    final percent = _frenchDecimal(value * 100, fractionDigits);
    final sign = value > 0 && !_isZero(percent) ? '+' : '';
    return '$sign$percent$_nonBreakingSpace%';
  }

  String toFrenchPrice(String currency) {
    final value = this;
    if (value == null) return _missingValue;
    return '${_frenchDecimal(value, 2)}$_nonBreakingSpace$currency';
  }

  String toFrenchDecimal() {
    final value = this;
    if (value == null) return _missingValue;
    return _frenchDecimal(value, 2);
  }
}

String _frenchDecimal(double value, int fractionDigits) {
  final [integerPart, ...decimalPart] = value
      .abs()
      .toStringAsFixed(fractionDigits)
      .split('.');
  final groupedIntegerPart = integerPart.replaceAllMapped(
    RegExp(r'\d(?=(\d{3})+$)'),
    (match) => '${match[0]}$_nonBreakingSpace',
  );
  final formatted = [groupedIntegerPart, ...decimalPart].join(',');
  return value < 0 && !_isZero(formatted) ? '-$formatted' : formatted;
}

bool _isZero(String formatted) => RegExp(r'^[0,]+$').hasMatch(formatted);

enum ValueTrend { gain, loss, neutral }

extension ValueTrendOfRate on double? {
  ValueTrend get trend {
    final value = this;
    if (value == null || _isZero(_frenchDecimal(value * 100, 2))) {
      return ValueTrend.neutral;
    }
    return value > 0 ? ValueTrend.gain : ValueTrend.loss;
  }
}
