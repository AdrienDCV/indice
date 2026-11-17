import 'package:flutter/material.dart';

/// Une icône suivie d'un court texte (durée, niveau…).
/// Le texte se termine par « … » s'il manque de place.
class InfoItem extends StatelessWidget {
  const InfoItem({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
