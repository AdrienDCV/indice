import 'package:flutter/material.dart';

import '../badge/leverage_badge.dart';

class EtfCard extends StatelessWidget {
  const EtfCard({
    super.key,
    required this.name,
    required this.ticker,
    required this.exchange,
    required this.currency,
    required this.isFavourite,
    required this.isLeveragedOrInverse,
    required this.onFavouriteTap,
    this.onTap,
  });

  final String name;
  final String ticker;
  final String exchange;
  final String currency;
  final bool isFavourite;
  final bool isLeveragedOrInverse;
  final VoidCallback onFavouriteTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 16,
            children: [
              Text(
                ticker,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(name, style: theme.textTheme.titleSmall),
                    Text(
                      '$exchange · $currency',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isLeveragedOrInverse) const LeverageBadge(),
                  ],
                ),
              ),
              IconButton(
                onPressed: onFavouriteTap,
                icon: Icon(
                  isFavourite ? Icons.star : Icons.star_border,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
