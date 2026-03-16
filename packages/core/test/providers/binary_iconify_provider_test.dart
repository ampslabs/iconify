import 'dart:io';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryIconifyProvider', () {
    late Directory tempDir;
    late BinaryIconifyProvider provider;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('iconify_binary_test');

      const collection = ParsedCollection(
        prefix: 'mdi',
        info: IconifyCollectionInfo(prefix: 'mdi', name: 'MDI', totalIcons: 1),
        icons: {'home': IconifyIconData(body: '<path d="home"/>')},
        aliases: {},
        defaultWidth: 24,
        defaultHeight: 24,
      );

      final encoded = BinaryIconFormat.encode(collection);
      final mdiFile = File('${tempDir.path}/mdi.iconbin');
      await mdiFile.writeAsBytes(encoded);

      provider = BinaryIconifyProvider(root: tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('loads icon from .iconbin file', () async {
      final icon = await provider.getIcon(const IconifyName('mdi', 'home'));
      expect(icon, isNotNull);
      expect(icon!.body, contains('home'));
    });

    test('getCollection returns info from file', () async {
      final collection = await provider.getCollection('mdi');
      expect(collection?.prefix, 'mdi');
      expect(collection?.totalIcons, 1);
    });

    test('returns null for missing collection', () async {
      final icon = await provider.getIcon(const IconifyName('ghost', 'home'));
      expect(icon, isNull);
    });

    test('hasIcon returns true for existing icon', () async {
      expect(await provider.hasIcon(const IconifyName('mdi', 'home')), isTrue);
    });

    test('hasCollection returns true for existing file', () async {
      expect(await provider.hasCollection('mdi'), isTrue);
    });

    test('preloadAll loads files into cache', () async {
      final preloadedProvider =
          BinaryIconifyProvider(root: tempDir.path, preload: true);

      // Wait a bit for isolate preloading to finish since it's fire-and-forget in constructor
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final icon =
          await preloadedProvider.getIcon(const IconifyName('mdi', 'home'));
      expect(icon, isNotNull);
    });

    test('preloadPrefixes selectively loads files', () async {
      final preloadedProvider =
          BinaryIconifyProvider(root: tempDir.path, preloadPrefixes: ['mdi']);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final icon =
          await preloadedProvider.getIcon(const IconifyName('mdi', 'home'));
      expect(icon, isNotNull);
    });
  });
}
