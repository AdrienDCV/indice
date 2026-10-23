import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/utils/number_formatting.dart';

void main() {
  test('formats a rate as a percentage with two decimals', () {
    expect(0.161.toFrenchPercent(), '16,10 %');
    expect(0.0.toFrenchPercent(), '0,00 %');
    expect(0.12866.toFrenchPercent(), '12,87 %');
  });

  test('formats a rate as a signed percentage', () {
    expect(0.142.toFrenchSignedPercent(), '+14,20 %');
    expect((-0.245).toFrenchSignedPercent(), '-24,50 %');
    expect(0.0.toFrenchSignedPercent(), '0,00 %');
    expect(0.00001.toFrenchSignedPercent(), '0,00 %');
    expect((-0.00001).toFrenchSignedPercent(), '0,00 %');
  });

  test('formats a price with its currency and grouped thousands', () {
    expect(766.48.toFrenchPrice('USD'), '766,48 USD');
    expect(1234.5.toFrenchPrice('USD'), '1 234,50 USD');
    expect(1234567.0.toFrenchPrice('USD'), '1 234 567,00 USD');
  });

  test('replaces a missing value with a dash', () {
    const double? missing = null;

    expect(missing.toFrenchPercent(), '—');
    expect(missing.toFrenchSignedPercent(), '—');
    expect(missing.toFrenchPrice('USD'), '—');
  });

  test('tells whether a rate is a gain, a loss or neither', () {
    const double? missing = null;

    expect(0.142.trend, ValueTrend.gain);
    expect((-0.245).trend, ValueTrend.loss);
    expect(0.0.trend, ValueTrend.neutral);
    expect(0.00001.trend, ValueTrend.neutral);
    expect((-0.00001).trend, ValueTrend.neutral);
    expect(missing.trend, ValueTrend.neutral);
  });
}
