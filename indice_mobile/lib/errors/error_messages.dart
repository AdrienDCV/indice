const _genericMessage =
    'Une erreur est survenue. Réessaie dans quelques instants.';

const unexpectedErrorKey = 'error.unexpected';

const _messages = {
  unexpectedErrorKey:
      'Une erreur inattendue est survenue. Réessaie dans quelques instants.',
};

String errorMessage(String key) => _messages[key] ?? _genericMessage;
