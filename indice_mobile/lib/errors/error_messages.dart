const _genericMessage =
    'Une erreur est survenue. Réessaie dans quelques instants.';

const unexpectedErrorKey = 'error.unexpected';

const _messages = {
  unexpectedErrorKey:
      'Une erreur inattendue est survenue. Réessaie dans quelques instants.',
  'error.etfs.etf-not-found': 'Cet ETF est introuvable.',
  'error.etfs.invalid-ticker': 'Ce code d’ETF n’est pas valide.',
};

String errorMessage(String key) => _messages[key] ?? _genericMessage;
