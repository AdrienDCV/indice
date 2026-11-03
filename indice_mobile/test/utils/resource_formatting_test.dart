import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/models/resource/resource_level.dart';
import 'package:indice_mobile/models/resource/resource_type.dart';
import 'package:indice_mobile/utils/resource_formatting.dart';

void main() {
  test('formats a duration in minutes', () {
    expect(5.toFrenchDuration(), '5 min');
  });

  test('labels every level in french', () {
    expect(ResourceLevel.values.map((level) => level.label), [
      'Débutant',
      'Intermédiaire',
      'Expérimenté',
      'Professionnel',
    ]);
  });

  test('labels every type in french', () {
    expect(ResourceType.video.label, 'Vidéo');
    expect(ResourceType.article.label, 'Article');
  });
}
