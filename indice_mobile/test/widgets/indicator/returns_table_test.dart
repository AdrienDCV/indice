import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/theme/app_theme.dart';
import 'package:indice_mobile/theme/gain_loss_colors.dart';
import 'package:indice_mobile/utils/number_formatting.dart';
import 'package:indice_mobile/widgets/indicator/returns_table.dart';

void main() {
  testWidgets('shows each period above its colored return', (
    WidgetTester tester,
  ) async {
    final theme = buildAppTheme();
    final colors = theme.extension<GainLossColors>()!;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: ReturnsTable(
            returns: [
              (period: '1 an', value: '+14,20 %', trend: ValueTrend.gain),
              (period: '3 ans', value: '-5,00 %', trend: ValueTrend.loss),
              (period: '5 ans', value: '—', trend: ValueTrend.neutral),
            ],
          ),
        ),
      ),
    );

    Color? colorOf(String text) =>
        tester.widget<Text>(find.text(text)).style?.color;

    expect(find.text('1 an'), findsOneWidget);
    expect(find.text('3 ans'), findsOneWidget);
    expect(find.text('5 ans'), findsOneWidget);
    expect(colorOf('+14,20 %'), colors.gain);
    expect(colorOf('-5,00 %'), colors.loss);
    expect(colorOf('—'), isNot(anyOf(colors.gain, colors.loss)));
  });
}
