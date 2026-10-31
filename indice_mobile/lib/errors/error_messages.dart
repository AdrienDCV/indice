const _genericMessage =
    'Une erreur est survenue. Réessaie dans quelques instants.';

const unexpectedErrorKey = 'error.unexpected';

const _messages = {
  unexpectedErrorKey:
      'Une erreur inattendue est survenue. Réessaie dans quelques instants.',
  'error.etfs.etf-not-found': 'Cet ETF est introuvable.',
  'error.etfs.invalid-ticker': 'Ce code d’ETF n’est pas valide.',
  'error.etfs.etf-a-insufficient-data':
      'Comparaison impossible : {etfA} n’a pas assez d’historique '
      '(au moins un an est nécessaire).',
  'error.etfs.etf-b-insufficient-data':
      'Comparaison impossible : {etfB} n’a pas assez d’historique '
      '(au moins un an est nécessaire).',
  'error.etfs.etfs-insufficient-data':
      'Comparaison impossible : {etfA} et {etfB} n’ont pas assez '
      'd’historique en commun (au moins un an est nécessaire).',
  'error.etfs.same-etf-comparison': 'Choisis deux ETF différents.',
  'error.request.missing-parameter': 'Choisis deux ETF pour les comparer.',
};

String errorMessage(String key, {Map<String, String> params = const {}}) {
  final message = _messages[key] ?? _genericMessage;
  return params.entries.fold(
    message,
    (text, param) => text.replaceAll('{${param.key}}', param.value),
  );
}
