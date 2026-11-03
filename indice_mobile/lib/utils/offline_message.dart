import 'date_formatting.dart';

String offlineMessage(DateTime cachedAt) =>
    'Hors ligne · données du ${cachedAt.toFrenchDateTime()}';
