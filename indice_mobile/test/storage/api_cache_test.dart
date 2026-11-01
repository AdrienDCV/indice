import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/storage/api_cache.dart';

void main() {
  late Directory directory;
  final cachedAt = DateTime.utc(2026, 10, 30, 13, 5);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('api_cache_test');
  });

  tearDown(() => directory.delete(recursive: true));

  test('reads back the written response with its date', () async {
    final cache = ApiCache(directory, now: () => cachedAt);

    await cache.write('etf_catalog', {'stale': false});
    final cached = await cache.read('etf_catalog');

    expect(cached!.response, {'stale': false});
    expect(cached.cachedAt, cachedAt);
  });

  test('stores one json file per key', () async {
    final cache = ApiCache(directory, now: () => cachedAt);

    await cache.write('etf_detail_SPY', {'ticker': 'SPY'});

    expect(
      File('${directory.path}/etf_detail_SPY.json').readAsStringSync(),
      '{"cachedAt":"2026-10-30T13:05:00.000Z","response":{"ticker":"SPY"}}',
    );
  });

  test('replaces the previous response of a key', () async {
    var now = DateTime.utc(2026, 10, 29);
    final cache = ApiCache(directory, now: () => now);
    await cache.write('etf_detail_SPY', {'stale': true});
    now = cachedAt;

    await cache.write('etf_detail_SPY', {'stale': false});
    final cached = await cache.read('etf_detail_SPY');

    expect(cached!.response, {'stale': false});
    expect(cached.cachedAt, cachedAt);
  });

  test('creates its directory when it does not exist yet', () async {
    final cache = ApiCache(
      Directory('${directory.path}/api_cache'),
      now: () => cachedAt,
    );

    await cache.write('etf_catalog', {'stale': false});

    expect(await cache.read('etf_catalog'), isNotNull);
  });

  test('returns nothing for a key that was never written', () async {
    expect(await ApiCache(directory).read('etf_detail_QQQ'), isNull);
  });

  test('returns nothing for a corrupted file', () async {
    File('${directory.path}/etf_catalog.json').writeAsStringSync('{"cach');

    expect(await ApiCache(directory).read('etf_catalog'), isNull);
  });

  test('returns nothing for a file without its expected fields', () async {
    File('${directory.path}/etf_catalog.json')
        .writeAsStringSync('{"response":{"stale":false}}');

    expect(await ApiCache(directory).read('etf_catalog'), isNull);
  });

  test('ignores a write that fails', () async {
    final notADirectory = File('${directory.path}/file')..writeAsStringSync('');
    final cache = ApiCache(Directory(notADirectory.path));

    await cache.write('etf_catalog', {'stale': false});

    expect(await cache.read('etf_catalog'), isNull);
  });

  test('deletes a written response', () async {
    final cache = ApiCache(directory, now: () => cachedAt);
    await cache.write('etf_detail_SPY', {'ticker': 'SPY'});

    await cache.delete('etf_detail_SPY');

    expect(await cache.read('etf_detail_SPY'), isNull);
  });

  test('ignores the deletion of a missing response', () async {
    await ApiCache(directory).delete('etf_detail_QQQ');

    expect(await ApiCache(directory).read('etf_detail_QQQ'), isNull);
  });

  test('reads every readable response whose key has the prefix', () async {
    final cache = ApiCache(directory, now: () => cachedAt);
    await cache.write('etf_detail_SPY', {'ticker': 'SPY'});
    await cache.write('etf_detail_QQQ', {'ticker': 'QQQ'});
    await cache.write('other', {'ticker': 'BND'});
    File('${directory.path}/etf_detail_BAD.json').writeAsStringSync('{"cach');

    final responses = await cache.readAll('etf_detail_');

    expect(responses.map((cached) => cached.response['ticker']).toSet(), {
      'SPY',
      'QQQ',
    });
  });

  test('reads nothing when its directory does not exist yet', () async {
    final cache = ApiCache(Directory('${directory.path}/missing'));

    expect(await cache.readAll('etf_detail_'), isEmpty);
  });
}
