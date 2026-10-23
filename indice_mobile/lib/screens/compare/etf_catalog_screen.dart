import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/error_messages.dart';
import '../../models/etf/etf_catalog_data.dart';
import '../../stores/etf/etf_catalog_state.dart';
import '../../stores/etf/etf_catalog_store.dart';
import '../../utils/date_formatting.dart';
import '../../widgets/banner/stale_data_banner.dart';
import '../../widgets/card/etf_card.dart';

class EtfCatalogScreen extends StatelessWidget {
  const EtfCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comparer')),
      body: BlocBuilder<EtfCatalogStore, EtfCatalogState>(
        builder: (context, state) {
          final errorKey = state.errorKey;
          final catalog = state.catalog;
          if (errorKey != null) {
            return _ErrorView(
              message: errorMessage(errorKey),
              onRetry: context.read<EtfCatalogStore>().init,
            );
          }
          if (state.isLoading || catalog == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _CatalogView(catalog: catalog);
        },
      ),
    );
  }
}

class _CatalogView extends StatelessWidget {
  const _CatalogView({required this.catalog});

  final EtfCatalogData catalog;

  @override
  Widget build(BuildContext context) {
    final etfs = catalog.etfs.content;
    final fetchedAt = catalog.fetchedAt;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (catalog.stale)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StaleDataBanner(
              message: fetchedAt == null
                  ? 'Le catalogue n’a pas pu être mis à jour.'
                  : 'Le catalogue n’a pas pu être mis à jour. '
                        'Dernière mise à jour le ${fetchedAt.toFrenchDate()}.',
            ),
          ),
        if (etfs.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Text(
              'Aucun ETF disponible pour le moment.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final etf in etfs)
          EtfCard(
            name: etf.name,
            ticker: etf.ticker,
            exchange: etf.exchange,
            currency: etf.currency,
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(message, textAlign: TextAlign.center),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
