import 'package:flutter/material.dart';

import '../data/fake_resources.dart';
import '../widgets/module_button.dart';
import '../widgets/resource_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Prêt à découvrir\nl’investissement ?',
            style: TextStyle(color: Color(0xFF61B396), fontSize: 32),
          ),
          const SizedBox(height: 16),
          ModuleButton(
            title: 'Apprendre',
            subtitle: 'Comprendre les bases des ETF et de la finance',
            onTap: () {},
          ),
          const SizedBox(height: 32),
          const Text(
            'Nouveauté pédagogique :',
            style: TextStyle(
              color: Color(0xFF307A60),
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          for (final resource in fakeResources)
            ResourceCard(
              title: resource.title,
              description: resource.description,
              duration: resource.duration,
              isFavorite: false,
              onFavoriteTap: () {},
            ),
        ],
      ),
    );
  }
}
