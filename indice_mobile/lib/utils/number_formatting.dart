const _missingValue = '—';
const _nonBreakingSpace = ' ';

extension NumberFormatting on double? {
  String toFrenchPercent() {
    final value = this;
    if (value == null) return _missingValue;
    return '${_frenchDecimal(value * 100)}$_nonBreakingSpace%';
  }

  String toFrenchSignedPercent() {
    final value = this;
    if (value == null) return _missingValue;
    final percent = _frenchDecimal(value * 100);
    final sign = value > 0 && percent != '0,00' ? '+' : '';
    return '$sign$percent$_nonBreakingSpace%';
  }

  String toFrenchPrice(String currency) {
    final value = this;
    if (value == null) return _missingValue;
    return '${_frenchDecimal(value)}$_nonBreakingSpace$currency';
  }
}

String _frenchDecimal(double value) {
  final [integerPart, decimalPart] = value.abs().toStringAsFixed(2).split('.');
  final groupedIntegerPart = integerPart.replaceAllMapped(
    RegExp(r'\d(?=(\d{3})+$)'),
    (match) => '${match[0]}$_nonBreakingSpace',
  );
  final formatted = '$groupedIntegerPart,$decimalPart';
  final isNegative = value < 0 && formatted != '0,00';
  return isNegative ? '-$formatted' : formatted;
}

enum ValueTrend { gain, loss, neutral }

extension ValueTrendOfRate on double? {
  ValueTrend get trend {
    final value = this;
    if (value == null || _frenchDecimal(value * 100) == '0,00') {
      return ValueTrend.neutral;
    }
    return value > 0 ? ValueTrend.gain : ValueTrend.loss;
  }
}
