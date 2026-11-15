import '../utils/date_formatting.dart';

abstract final class EtfCatalogTexts {
  static const leverageInfo =
      'Certains ETF amplifient (effet de levier) ou inversent les variations '
      'd’un indice : ils sont conçus pour des opérations de très court terme. '
      'Ceux repérés d’après leur nom portent une étiquette.';

  static String staleMessage(DateTime? fetchedAt) => fetchedAt == null
      ? 'Le catalogue n’a pas pu être mis à jour.'
      : 'Le catalogue n’a pas pu être mis à jour. '
            'Dernière mise à jour le ${fetchedAt.toFrenchDate()}.';

  static const offlineEmptyMessage =
      'Aucun favori disponible hors ligne. Épinglez un ETF pour le retrouver '
      'sans connexion.';

  static const noEtfMessage = 'Aucun ETF disponible pour le moment.';

  static const noFavouriteMessage =
      'Aucun favori pour le moment. Touchez l’étoile d’un ETF pour l’ajouter.';

  static String noEtfMatchingMessage(String search) =>
      'Aucun ETF ne correspond à « $search ».';

  static String noFavouriteMatchingMessage(String search) =>
      'Aucun favori ne correspond à « $search ».';
}

abstract final class EtfPickerTexts {
  static const offlineEmptyMessage = 'Aucun favori disponible hors ligne.';

  static const noEtfMessage = 'Aucun ETF disponible pour le moment.';

  static String noEtfMatchingMessage(String search) =>
      'Aucun ETF ne correspond à « $search ».';
}

abstract final class EtfDetailTexts {
  static const leverageInfo =
      'D’après son nom, cet ETF amplifie (effet de levier) ou inverse les '
      'variations d’un indice, chaque jour. Sur plusieurs jours, sa '
      'performance peut fortement s’écarter de celle de l’indice. Il est conçu '
      'pour des opérations de très court terme.';

  static const noHistoryMessage =
      'Aucun historique de cours disponible pour le moment.';

  static const returnInfo =
      'Hausse ou baisse de la valeur de l’ETF sur 1, 3 et 5 ans, jusqu’au '
      'dernier cours. Les dividendes, la part des bénéfices versée par les '
      'entreprises, sont comptés comme s’ils avaient été réinvestis dans '
      'l’ETF. Par exemple, +20 % sur 5 ans : 100 € placés il y a 5 ans '
      'vaudraient 120 € aujourd’hui.';

  static const annualizedReturnInfo =
      'Gain ou perte moyen par an sur les 5 dernières années : c’est le taux '
      'qui, appliqué chaque année, donne le même rendement qu’en 5 ans. Par '
      'exemple, un ETF qui double en 5 ans a un rendement annualisé d’environ '
      '15 %.';

  static const volatilityInfo =
      'Mesure à quel point le prix monte et descend d’un jour à l’autre, sur '
      'la dernière année. Plus elle est élevée, plus le prix bouge fort, à la '
      'hausse comme à la baisse.';

  static const maxDrawdownInfo =
      'Plus forte baisse entre un sommet et le creux qui a suivi, sur 5 ans. '
      'Elle montre ce qu’un investisseur aurait pu perdre au pire moment.';

  static const priceRangeInfo =
      'Plus bas et plus haut cours de clôture de la dernière année. Le curseur '
      'situe le dernier cours dans cette fourchette.';

  static String priceChartInfo(DateTime historyStartDate) =>
      'Cours de clôture de chaque jour de bourse, ajustés des dividendes '
      'réinvestis : les cours passés sont corrigés pour rester comparables à '
      'celui d’aujourd’hui, ils peuvent donc différer du prix affiché à '
      'l’époque. Le pourcentage indique la variation depuis le '
      '${historyStartDate.toFrenchDate()}, début de l’historique.';

  static String staleMessage(DateTime lastCloseDate) =>
      'Données au ${lastCloseDate.toFrenchDate()}, mise à jour impossible.';

  static String historyStartMessage(DateTime historyStartDate) =>
      'Historique disponible depuis le ${historyStartDate.toFrenchDate()}.';

  static const pastPerformanceNote =
      'Les performances passées ne préjugent pas des performances futures.';
}

abstract final class EtfComparisonTexts {
  static const noHistoryMessage =
      'Aucun historique de cours disponible pour le moment.';

  static const commonPeriodInfo =
      'Les indicateurs sont calculés sur les dates où les deux ETF ont un '
      'cours, pour les comparer sur la même période.';

  static const totalReturnInfo =
      'Hausse ou baisse de la valeur de l’ETF entre le premier et le dernier '
      'jour de la période commune aux deux ETF. Les dividendes, la part des '
      'bénéfices versée par les entreprises, sont comptés comme s’ils avaient '
      'été réinvestis dans l’ETF. Par exemple, +20 % : 100 € placés au début '
      'vaudraient 120 € à la fin.';

  static const annualizedReturnInfo =
      'Gain ou perte moyen par an sur la période commune aux deux ETF : c’est '
      'le taux qui, appliqué chaque année, donne le même rendement total. Par '
      'exemple, un ETF qui double en 5 ans a un rendement annualisé d’environ '
      '15 %.';

  static const volatilityInfo =
      'Mesure à quel point le prix monte et descend d’un jour à l’autre, sur '
      'la période commune aux deux ETF, exprimée pour une année. Plus elle est '
      'élevée, plus le prix bouge fort, à la hausse comme à la baisse.';

  static const returnToRiskRatioInfo =
      'Rendement annualisé divisé par la volatilité. Il indique le rendement '
      'obtenu pour chaque point de variation du prix : plus il est élevé, '
      'moins le prix a varié pour obtenir ce rendement. Par exemple, un '
      'rendement annualisé de 10 % avec une volatilité de 20 % donne un ratio '
      'de 0,5.';

  static const maxDrawdownInfo =
      'Plus forte baisse entre un sommet et le creux qui a suivi. Elle montre '
      'ce qu’un investisseur aurait pu perdre au pire moment.';

  static const correlationInfo =
      'Entre −1 et 1, elle indique si les deux ETF évoluent ensemble. Proche '
      'de 1 : ils montent et baissent souvent les mêmes jours, donc détenir '
      'les deux réduit peu les variations. Proche de 0 : leurs mouvements sont '
      'peu liés. Proche de −1 : quand l’un monte, l’autre a tendance à '
      'baisser.';

  static String priceChartInfo(DateTime startDate) =>
      'Cours de clôture ajustés des dividendes réinvestis. Les pourcentages '
      'indiquent la variation de chaque ETF depuis le '
      '${startDate.toFrenchDate()}, début de la période commune : les deux '
      'courbes partent de 0 %.';

  static const chooseTwoEtfsMessage = 'Choisissez deux ETF pour les comparer.';

  static String staleMessage(String ticker, DateTime? fetchedAt) {
    final message = 'Les données de $ticker n’ont pas pu être mises à jour.';
    return fetchedAt == null
        ? message
        : '$message Dernière mise à jour le ${fetchedAt.toFrenchDate()}.';
  }

  static const pastPerformanceNote =
      'Les performances passées ne préjugent pas des performances futures.';
}
