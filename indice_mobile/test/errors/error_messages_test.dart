import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/errors/error_messages.dart';

void main() {
  test('translates a known error key', () {
    expect(
      errorMessage('error.etfs.etf-not-found'),
      'Cet ETF est introuvable.',
    );
  });

  test('explains a connection failure', () {
    expect(
      errorMessage(networkErrorKey),
      'Connexion impossible pour le moment. '
      'Vérifiez votre connexion puis réessayez.',
    );
  });

  test('explains a server that takes too long to answer', () {
    expect(
      errorMessage(serverTimeoutErrorKey),
      'Le serveur met trop de temps à répondre. '
      'Réessayez dans quelques instants.',
    );
  });

  test('shows a cloud for a connection failure, a warning otherwise', () {
    expect(errorIcon(networkErrorKey), Icons.cloud_off);
    expect(errorIcon(serverTimeoutErrorKey), Icons.error_outline);
    expect(errorIcon(unexpectedErrorKey), Icons.error_outline);
  });

  test('falls back to a generic message for an unknown key', () {
    expect(
      errorMessage('error.unknown'),
      'Une erreur est survenue. Réessayez dans quelques instants.',
    );
  });

  test('inserts the given parameters into the message', () {
    expect(
      errorMessage(
        'error.etfs.etfs-insufficient-data',
        params: {'etfA': 'SPY', 'etfB': 'QQQ'},
      ),
      'Comparaison impossible : SPY et QQQ n’ont pas assez d’historique en '
      'commun (au moins un an est nécessaire).',
    );
  });

  test('ignores parameters that the message does not use', () {
    expect(
      errorMessage(
        'error.etfs.etf-a-insufficient-data',
        params: {'etfA': 'SPY', 'etfB': 'QQQ'},
      ),
      'Comparaison impossible : SPY n’a pas assez d’historique '
      '(au moins un an est nécessaire).',
    );
  });
}
