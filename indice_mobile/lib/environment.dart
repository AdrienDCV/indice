import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class Environment {
  static String get apiUrl => dotenv.get('API_BASE_URL');
}
