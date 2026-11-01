import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

typedef CachedResponse = ({Map<String, dynamic> response, DateTime cachedAt});

class ApiCache {
  ApiCache(this._directory, {this._now = DateTime.now});

  final Directory _directory;
  final DateTime Function() _now;

  Future<void> write(String key, Map<String, dynamic> response) async {
    try {
      await _directory.create(recursive: true);
      await _fileOf(key).writeAsString(
        jsonEncode({
          'cachedAt': _now().toUtc().toIso8601String(),
          'response': response,
        }),
      );
    } on FileSystemException catch (error) {
      _log('écriture de $key impossible : $error');
    }
  }

  Future<CachedResponse?> read(String key) async {
    final file = _fileOf(key);
    try {
      if (!await file.exists()) return null;
      final content = jsonDecode(await file.readAsString());
      if (content is! Map<String, dynamic>) return null;
      final cachedAt = content['cachedAt'];
      final response = content['response'];
      if (cachedAt is! String || response is! Map<String, dynamic>) {
        return null;
      }
      return (response: response, cachedAt: DateTime.parse(cachedAt));
    } on FileSystemException catch (error) {
      _log('lecture de $key impossible : $error');
    } on FormatException catch (error) {
      _log('fichier $key illisible : $error');
    }
    return null;
  }

  Future<void> delete(String key) async {
    try {
      final file = _fileOf(key);
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (error) {
      _log('suppression de $key impossible : $error');
    }
  }

  Future<List<CachedResponse>> readAll(String prefix) async {
    final List<FileSystemEntity> files;
    try {
      if (!await _directory.exists()) return const [];
      files = await _directory.list().toList();
    } on FileSystemException catch (error) {
      _log('lecture du dossier impossible : $error');
      return const [];
    }
    final responses = <CachedResponse>[];
    for (final file in files.whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (!name.startsWith(prefix) || !name.endsWith('.json')) continue;
      final cached = await read(name.substring(0, name.length - 5));
      if (cached != null) responses.add(cached);
    }
    return responses;
  }

  File _fileOf(String key) => File('${_directory.path}/$key.json');

  void _log(String message) {
    if (kDebugMode) debugPrint('ApiCache : $message');
  }
}
