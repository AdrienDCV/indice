import 'package:flutter/material.dart';

class FilterToggle extends StatelessWidget {
  const FilterToggle({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contentColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.primary;

    return FilterChip(
      label: Text(label),
      avatar: icon == null ? null : Icon(icon, color: contentColor),
      selected: isSelected,
      onSelected: onSelected,
      showCheckmark: false,
      labelStyle: TextStyle(color: contentColor, fontWeight: FontWeight.w600),
      color: WidgetStatePropertyAll(
        isSelected ? colorScheme.primary : Colors.transparent,
      ),
      side: BorderSide(color: colorScheme.primary, width: 1.5),
      shape: const StadiumBorder(),
    );
  }
}
