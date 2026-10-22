import 'package:flutter/material.dart';

import '../data/fake_resources.dart';
import '../widgets/module_button.dart';
import '../widgets/resource_card.dart';
import 'resource_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onLearnTap});

  final VoidCallback onLearnTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Prêt à découvrir\nl’investissement ?',
            style: textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          ModuleButton(
            title: 'Apprendre',
            subtitle: 'Comprendre les bases des ETF et de la finance',
            onTap: onLearnTap,
          ),
          const SizedBox(height: 32),
          Text('Nouveauté pédagogique :', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final resource in fakeResources)
            ResourceCard(
              resource: resource,
              onTap: () =>
                  Navigator.of(context)
                      .push(ResourceDetailPage.route(resource)),
              onFavoriteTap: () {},
            ),
        ],
      ),
    );
  }
}
