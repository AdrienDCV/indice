import '../models/resource/resource_level.dart';
import '../models/resource/resource_type.dart';

extension ResourceLevelLabel on ResourceLevel {
  String get label => switch (this) {
    ResourceLevel.beginner => 'Débutant',
    ResourceLevel.intermediate => 'Intermédiaire',
    ResourceLevel.experienced => 'Expérimenté',
    ResourceLevel.professional => 'Professionnel',
  };
}

extension ResourceTypeLabel on ResourceType {
  String get label => switch (this) {
    ResourceType.video => 'Vidéo',
    ResourceType.article => 'Article',
  };
}

extension DurationFormatting on int {
  /// Durée en minutes : `5` → `5 min`.
  String toFrenchDuration() => '$this min';
}
