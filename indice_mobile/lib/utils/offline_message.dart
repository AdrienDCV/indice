import 'date_formatting.dart';

const offlineFavouritesMessage =
    'Hors ligne · seuls vos favoris téléchargés sont disponibles';

String offlineMessage(DateTime cachedAt) =>
    'Hors ligne · données du ${cachedAt.toFrenchDateTime()}';
