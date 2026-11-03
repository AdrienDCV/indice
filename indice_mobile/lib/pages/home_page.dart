import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../stores/resource/resource_catalog_state.dart';
import '../stores/resource/resource_catalog_store.dart';
import '../theme/module_colors.dart';
import '../utils/page_padding.dart';
import '../utils/resource_formatting.dart';
import '../widgets/card/resource_card.dart';
import '../widgets/module_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
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
          const SizedBox(height: 16),
          ModuleButton(
            title: 'Comparer',
            subtitle: 'Apprendre à lire et comparer les indicateurs des ETF',
            color: Theme.of(context).extension<ModuleColors>()?.compare,
            onTap: () => context.go('/compare'),
          ),
          const SizedBox(height: 32),
          Text('Nouveauté pédagogique :', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          BlocBuilder<ResourceCatalogStore, ResourceCatalogState>(
            builder: (context, state) => Column(
              children: [
                for (final resource in state.resources)
                  ResourceCard(
                    title: resource.title,
                    description: resource.description,
                    duration: resource.durationMinutes.toFrenchDuration(),
                    type: resource.type,
                    isFavourite: resource.favourite,
                    onTap: () => context.push('/resource/${resource.id}'),
                    onFavouriteTap: () => context
                        .read<ResourceCatalogStore>()
                        .toggleFavourite(resource.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
