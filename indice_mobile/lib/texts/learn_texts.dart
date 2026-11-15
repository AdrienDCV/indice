abstract final class LearnTexts {
  static const offlineEmptyMessage =
      'Aucun favori disponible hors ligne. Épinglez une ressource pour la '
      'retrouver sans connexion.';

  static const noResourceMessage =
      'Aucune ressource disponible pour le moment.';

  static const noFavouriteMessage =
      'Aucun favori pour le moment. Touchez le marque-page d’une ressource '
      'pour l’ajouter.';

  static const noResourceMatchingFiltersMessage =
      'Aucune ressource ne correspond à ces filtres.';

  static String noResourceMatchingMessage(String search) =>
      'Aucune ressource ne correspond à « $search ».';
}

abstract final class ResourceDetailTexts {
  static const videoOfflineMessage = 'La vidéo demande une connexion.';
}
