import 'dart:convert';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('Iconify Performance Benchmarks', () {
    test('IconifyName.parse benchmark (100k iterations)', () {
      final watch = Stopwatch()..start();
      for (var i = 0; i < 100000; i++) {
        IconifyName.parse('mdi:home');
      }
      watch.stop();
      // Use print to output benchmark results to the console.
      // ignore: avoid_print
      print('  IconifyName.parse: ${watch.elapsedMilliseconds}ms total');
      expect(watch.elapsedMilliseconds, lessThan(500),
          reason: 'Should be extremely fast');
    });

    test('LruIconifyCache.get benchmark (100k iterations)', () async {
      final cache = LruIconifyCache(maxEntries: 500);
      final name = const IconifyName('mdi', 'home');
      final data = const IconifyIconData(body: '<path/>');
      await cache.put(name, data);

      final watch = Stopwatch()..start();
      for (var i = 0; i < 100000; i++) {
        await cache.get(name);
      }
      watch.stop();
      // Use print to output benchmark results to the console.
      // ignore: avoid_print
      print('  LruIconifyCache.get: ${watch.elapsedMilliseconds}ms total');
      expect(watch.elapsedMilliseconds, lessThan(500));
    });

    test('IconifyJsonParser benchmark (Large collection)', () {
      final icons = <String, dynamic>{};
      for (var i = 0; i < 1000; i++) {
        icons['icon-$i'] = {'body': '<path d="$i"/>'};
      }
      final json = jsonEncode({
        'prefix': 'test',
        'icons': icons,
        'width': 24,
        'height': 24,
      });

      final watch = Stopwatch()..start();
      IconifyJsonParser.parseCollectionString(json);
      watch.stop();
      // Use print to output benchmark results to the console.
      // ignore: avoid_print
      print('  IconifyJsonParser (1000 icons): ${watch.elapsedMilliseconds}ms');
      expect(watch.elapsedMilliseconds, lessThan(500));
    });

    test('AliasResolver.resolve benchmark (10k chains depth-5)', () {
      final resolver = const AliasResolver();
      final icons = {'base': const IconifyIconData(body: '<path/>')};
      final aliases = {
        'a1': const AliasEntry(parent: 'base'),
        'a2': const AliasEntry(parent: 'a1'),
        'a3': const AliasEntry(parent: 'a2'),
        'a4': const AliasEntry(parent: 'a3'),
        'a5': const AliasEntry(parent: 'a4'),
      };

      final watch = Stopwatch()..start();
      for (var i = 0; i < 10000; i++) {
        resolver.resolve(
          iconName: 'a5',
          icons: icons,
          aliases: aliases,
          defaultWidth: 24,
          defaultHeight: 24,
        );
      }
      watch.stop();
      // Use print to output benchmark results to the console.
      // ignore: avoid_print
      print(
          '  AliasResolver (10k depth-5 chains): ${watch.elapsedMilliseconds}ms');
      expect(watch.elapsedMilliseconds, lessThan(500));
    });
  });
}
