import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/fake_resources.dart';
import '../widgets/module_button.dart';
import '../widgets/resource_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            onTap: () => context.go('/learn'),
          ),
          const SizedBox(height: 32),
          Text('Nouveauté pédagogique :', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final resource in fakeResources)
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
