import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/theme/app_theme.dart';
import 'package:indice_mobile/theme/gain_loss_colors.dart';
import 'package:indice_mobile/utils/number_formatting.dart';
import 'package:indice_mobile/widgets/indicator/indicator_tile.dart';
import 'package:indice_mobile/widgets/info/info_tooltip_button.dart';

Future<void> pumpTile(WidgetTester tester, {String? detail}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: IndicatorTile(
          label: 'Perte maximale sur 5 ans',
          value: '-24,50 %',
          infoText:
              'Plus forte baisse entre un sommet et le creux qui a suivi.',
          detail: detail,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('displays the label, the value and an info button', (
    WidgetTester tester,
  ) async {
    await pumpTile(tester);

    expect(find.text('Perte maximale sur 5 ans'), findsOneWidget);
    expect(find.text('-24,50 %'), findsOneWidget);
    expect(find.byType(InfoTooltipButton), findsOneWidget);
  });

  testWidgets('displays the detail when there is one', (
    WidgetTester tester,
  ) async {
    await pumpTile(tester, detail: 'Du 03/01/2022 au 12/10/2022');

    expect(find.text('Du 03/01/2022 au 12/10/2022'), findsOneWidget);
  });

  testWidgets('colors the value according to its trend', (
    WidgetTester tester,
  ) async {
    final theme = buildAppTheme();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: IndicatorTile(
            label: 'Annualisé sur 5 ans',
            value: '+13,50 %',
            infoText: 'Rendement moyen par an sur 5 ans.',
            trend: ValueTrend.gain,
          ),
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('+13,50 %')).style?.color,
      theme.extension<GainLossColors>()!.gain,
    );
  });
}
