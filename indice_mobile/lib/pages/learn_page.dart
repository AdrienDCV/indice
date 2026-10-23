import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/level.dart';
import '../models/resource.dart';
import '../utils/filter_resources.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/filter_toggle.dart';
import '../widgets/resource_card.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key, required this.resources});

  final List<Resource> resources;

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  final Set<Level> _selectedLevels = {};
  bool _favoritesOnly = false;

  void _toggleLevel(Level level, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedLevels.add(level);
      } else {
        _selectedLevels.remove(level);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final resources = filterResources(
      widget.resources,
      levels: _selectedLevels,
      favoritesOnly: _favoritesOnly,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Apprendre')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSearchBar(
            hintText: 'Rechercher une vidéo ou un article',
            onChanged: (query) {},
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                FilterToggle(
                  label: 'Favoris',
                  icon: Icons.star,
                  isSelected: _favoritesOnly,
                  onSelected: (isSelected) =>
                      setState(() => _favoritesOnly = isSelected),
                ),
                for (final level in Level.values)
                  FilterToggle(
                    label: level.label,
                    isSelected: _selectedLevels.contains(level),
                    onSelected: (isSelected) => _toggleLevel(level, isSelected),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (resources.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Text(
                'Aucune formation ne correspond à ces filtres.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final resource in resources)
            ResourceCard(
              resource: resource,
              onTap: () => context.push('/resource', extra: resource),
              onFavoriteTap: () {},
            ),
        ],
      ),
    );
  }
}
