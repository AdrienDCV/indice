import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/utils/date_formatting.dart';

void main() {
  test('formats a date as day/month/year with two-digit day and month', () {
    expect(DateTime(2026, 1, 5).toFrenchDate(), '05/01/2026');
    expect(DateTime(2026, 12, 25).toFrenchDate(), '25/12/2026');
  });

  test('formats a utc date in local time', () {
    final utc = DateTime.utc(2026, 10, 7, 23, 30);
    final local = utc.toLocal();

    expect(
      utc.toFrenchDate(),
      DateTime(local.year, local.month, local.day).toFrenchDate(),
    );
  });
}
