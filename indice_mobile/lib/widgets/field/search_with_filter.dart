import 'package:flutter/material.dart';

import '../app_search_bar.dart';
import '../filter_toggle.dart';

class SearchWithFilter extends StatelessWidget {
  const SearchWithFilter({
    super.key,
    required this.hintText,
    required this.onSearchChanged,
    required this.filterLabel,
    required this.filterIcon,
    required this.isFilterSelected,
    required this.onFilterChanged,
  });

  final String hintText;
  final ValueChanged<String> onSearchChanged;
  final String filterLabel;
  final IconData filterIcon;
  final bool isFilterSelected;
  final ValueChanged<bool> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        AppSearchBar(hintText: hintText, onChanged: onSearchChanged),
        FilterToggle(
          label: filterLabel,
          icon: filterIcon,
          isSelected: isFilterSelected,
          onSelected: onFilterChanged,
        ),
      ],
    );
  }
}
