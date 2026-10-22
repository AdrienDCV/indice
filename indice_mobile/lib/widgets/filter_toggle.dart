import 'package:flutter/material.dart';

const _green = Color(0xFF336C4C);

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
    final contentColor = isSelected ? Colors.white : _green;

    return FilterChip(
      label: Text(label),
      avatar: icon == null ? null : Icon(icon, color: contentColor),
      selected: isSelected,
      onSelected: onSelected,
      showCheckmark: false,
      labelStyle: TextStyle(color: contentColor, fontWeight: FontWeight.w600),
      color: WidgetStatePropertyAll(isSelected ? _green : Colors.transparent),
      side: const BorderSide(color: _green, width: 1.5),
      shape: const StadiumBorder(),
    );
  }
}
