import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.enabled = true,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      hintText: hintText,
      leading: const Icon(Icons.search),
      elevation: const WidgetStatePropertyAll(0),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}
