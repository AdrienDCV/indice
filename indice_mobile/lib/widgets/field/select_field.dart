import 'package:flutter/material.dart';

class SelectField<T> extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.leading,
  });

  final String label;
  final List<({T value, String label})> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final selected = options.any((option) => option.value == value)
        ? value
        : null;

    return DropdownButtonFormField<T>(
      key: ValueKey(selected),
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: leading),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option.value,
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged == null
          ? null
          : (selected) {
              if (selected != null) onChanged(selected);
            },
    );
  }
}
