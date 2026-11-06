import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'apiValue')
enum ResourceLevel {
  beginner('BEGINNER'),
  intermediate('INTERMEDIATE'),
  experienced('EXPERIENCED'),
  professional('PROFESSIONAL');

  const ResourceLevel(this.apiValue);

  /// Valeur attendue par l'API, dans le JSON et dans le filtre `levels`.
  final String apiValue;
}
