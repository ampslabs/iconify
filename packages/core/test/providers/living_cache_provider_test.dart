import 'dart:convert';
import 'dart:typed_data';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

class MockLivingCacheStorage implements LivingCacheStorage {
  String? content;

  @override
  Future<Uint8List?> readBytes() async {
    return content != null ? Uint8List.fromList(utf8.encode(content!)) : null;
  }

  @override
  Future<void> writeBytes(Uint8List bytes) async {
    content = utf8.decode(bytes);
  }
}

void main() {
  group('LivingCacheProvider', () {
    late MockLivingCacheStorage storage;
    late LivingCacheProvider provider;

    setUp(() {
      storage = MockLivingCacheStorage();
      provider = LivingCacheProvider(
        storage: storage,
        debounceDuration: Duration.zero,
      );
    });

    test('loads empty icons when storage is empty', () async {
      final hasHome = await provider.hasIcon(const IconifyName('mdi', 'home'));
      expect(hasHome, isFalse);
    });

    test('adds and retrieves icons', () async {
      const name = IconifyName('mdi', 'home');
      const data = IconifyIconData(body: '<path d="home"/>');

      await provider.addIcon(name, data);
      final retrieved = await provider.getIcon(name);

      expect(retrieved, isNotNull);
      expect(retrieved!.body, data.body);
    });

    test('flushes to storage', () async {
      const name = IconifyName('mdi', 'home');
      const data = IconifyIconData(body: '<path d="home"/>');

      await provider.addIcon(name, data);
      await provider.flush();

      expect(storage.content, contains('mdi:home'));
      expect(storage.content, contains('home'));
    });

    test('attaches source info', () async {
      const name = IconifyName('mdi', 'home');
      const data = IconifyIconData(body: '<path d="home"/>');

      await provider.addIcon(name, data, source: 'remote');
      final retrieved = await provider.getIcon(name);

      expect(retrieved!.raw['source'], 'remote');
    });
  });
}
