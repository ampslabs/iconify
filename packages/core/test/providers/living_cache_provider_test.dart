import 'dart:convert';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

class MockStorage implements LivingCacheStorage {
  String? content;
  int writeCount = 0;

  @override
  Future<String?> read() async => content;

  @override
  Future<void> write(String content) async {
    this.content = content;
    writeCount++;
  }
}

void main() {
  group('LivingCacheProvider', () {
    late MockStorage storage;
    late LivingCacheProvider provider;

    setUp(() {
      storage = MockStorage();
      provider = LivingCacheProvider(
        storage: storage,
        debounceDuration: const Duration(milliseconds: 10),
      );
    });

    test('loads empty cache from null storage', () async {
      final hasIcon = await provider.hasIcon(const IconifyName('test', 'icon'));
      expect(hasIcon, isFalse);
    });

    test('loads existing icons from storage', () async {
      final json = {
        'schemaVersion': 1,
        'icons': {
          'test:icon': {
            'body': '<path d="M0 0h24v24H0z"/>',
            'width': 24.0,
            'height': 24.0,
          }
        }
      };
      storage.content = jsonEncode(json);

      final icon = await provider.getIcon(const IconifyName('test', 'icon'));
      expect(icon, isNotNull);
      expect(icon!.body, '<path d="M0 0h24v24H0z"/>');
    });

    test('adds icon and flushes to storage', () async {
      const name = IconifyName('test', 'new');
      const data = IconifyIconData(body: '<path/>');

      await provider.addIcon(name, data);

      // Wait for debounce
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(storage.writeCount, 1);
      expect(storage.content, contains('test:new'));
      expect(storage.content, contains('<path/>'));
    });

    test('debounces multiple writes', () async {
      await provider.addIcon(
          const IconifyName('test', '1'), const IconifyIconData(body: '1'));
      await provider.addIcon(
          const IconifyName('test', '2'), const IconifyIconData(body: '2'));
      await provider.addIcon(
          const IconifyName('test', '3'), const IconifyIconData(body: '3'));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(storage.writeCount, 1);
      expect(storage.content, contains('test:1'));
      expect(storage.content, contains('test:2'));
      expect(storage.content, contains('test:3'));
    });

    test('preserves source information', () async {
      const name = IconifyName('test', 'sourced');
      const data = IconifyIconData(body: 'body');

      await provider.addIcon(name, data, source: 'remote');
      await provider.flush();

      expect(storage.content, contains('"source": "remote"'));

      // Reload from storage
      final newProvider = LivingCacheProvider(storage: storage);
      final loadedIcon = await newProvider.getIcon(name);
      expect(loadedIcon!.raw['source'], 'remote');
    });
  });
}
