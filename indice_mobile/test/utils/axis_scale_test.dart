import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/utils/axis_scale.dart';

void main() {
  test('graduates prices five by five around their range', () {
    final scale = axisScaleOf([87.34, 95.1, 103.2]);

    expect(scale.interval, 5);
    expect(scale.min, 85);
    expect(scale.max, 105);
  });

  test('graduates a narrow range two by two', () {
    final scale = axisScaleOf([101.3, 108.9]);

    expect(scale.interval, 2);
    expect(scale.min, 100);
    expect(scale.max, 110);
  });

  test('keeps around five graduations on an expensive etf', () {
    final scale = axisScaleOf([412.8, 563.1]);

    expect(scale.interval, 50);
    expect(scale.min, 400);
    expect(scale.max, 600);
  });

  test('graduates a cheap etf with decimals', () {
    final scale = axisScaleOf([4.12, 5.87]);

    expect(scale.interval, closeTo(0.5, 1e-9));
    expect(scale.min, closeTo(4, 1e-9));
    expect(scale.max, closeTo(6, 1e-9));
  });

  test('graduates negative and positive rates around zero', () {
    final scale = axisScaleOf([-0.123, 0.412]);

    expect(scale.interval, closeTo(0.2, 1e-9));
    expect(scale.min, closeTo(-0.2, 1e-9));
    expect(scale.max, closeTo(0.6, 1e-9));
  });

  test('gives a flat series a non empty range', () {
    final scale = axisScaleOf([100, 100]);

    expect(scale.interval, 10);
    expect(scale.min, 100);
    expect(scale.max, 110);
  });

  test('gives a series flat at zero a non empty range', () {
    final scale = axisScaleOf([0, 0]);

    expect(scale.interval, 1);
    expect(scale.min, 0);
    expect(scale.max, 1);
  });

  test('counts the decimals an interval needs', () {
    expect(fractionDigitsOf(50), 0);
    expect(fractionDigitsOf(1), 0);
    expect(fractionDigitsOf(0.5), 1);
    expect(fractionDigitsOf(0.1), 1);
    expect(fractionDigitsOf(0.05), 2);
    expect(fractionDigitsOf(0.01), 2);
  });
}
