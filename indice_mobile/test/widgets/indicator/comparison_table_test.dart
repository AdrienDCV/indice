import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/theme/app_theme.dart';
import 'package:indice_mobile/theme/gain_loss_colors.dart';
import 'package:indice_mobile/utils/number_formatting.dart';
import 'package:indice_mobile/widgets/indicator/comparison_table.dart';
import 'package:indice_mobile/widgets/info/info_tooltip_button.dart';

void main() {
  testWidgets('shows the etfs, the indicators and their colored values', (
    WidgetTester tester,
  ) async {
    final theme = buildAppTheme();
    final colors = theme.extension<GainLossColors>()!;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ComparisonTable(
            columns: [
              (label: 'SPY', color: Colors.green),
              (label: 'QQQ', color: Colors.teal),
            ],
            rows: [
              (
                label: 'Rendement total',
                infoText: 'Gain ou perte sur toute la période.',
                values: [
                  (text: '+81,23 %', trend: ValueTrend.gain),
                  (text: '-5,00 %', trend: ValueTrend.loss),
                ],
              ),
              (
                label: 'Volatilité',
                infoText: 'Ampleur habituelle des variations.',
                values: [
                  (text: '17,12 %', trend: ValueTrend.neutral),
                  (text: '—', trend: ValueTrend.neutral),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    Color? colorOf(String text) =>
        tester.widget<Text>(find.text(text)).style?.color;

    expect(find.text('SPY'), findsOneWidget);
    expect(find.text('QQQ'), findsOneWidget);
    expect(find.text('Rendement total'), findsOneWidget);
    expect(find.text('Volatilité'), findsOneWidget);
    expect(find.byType(InfoTooltipButton), findsNWidgets(2));
    expect(colorOf('+81,23 %'), colors.gain);
    expect(colorOf('-5,00 %'), colors.loss);
    expect(colorOf('17,12 %'), isNot(anyOf(colors.gain, colors.loss)));
  });
}
