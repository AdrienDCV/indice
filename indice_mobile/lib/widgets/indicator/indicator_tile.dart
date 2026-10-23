import 'package:flutter/material.dart';

import '../../theme/gain_loss_colors.dart';
import '../../utils/number_formatting.dart';
import '../info/info_tooltip_button.dart';

class IndicatorTile extends StatelessWidget {
  const IndicatorTile({
    super.key,
    required this.label,
    required this.value,
    required this.infoText,
    this.detail,
    this.trend = ValueTrend.neutral,
  });

  final String label;
  final String value;
  final String infoText;
  final String? detail;
  final ValueTrend trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = this.detail;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(label, style: theme.textTheme.bodyLarge),
                  ),
                  InfoTooltipButton(title: label, text: infoText),
                ],
              ),
              if (detail != null)
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.extension<GainLossColors>()?.colorOf(trend),
          ),
        ),
      ],
    );
  }
}
