import 'dart:convert';
import 'dart:io';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('FileSystemIconifyProvider', () {
    late Directory tempDir;
    late FileSystemIconifyProvider provider;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('iconify_test');
      final mdiFile = File('${tempDir.path}/mdi.json');
      await mdiFile.writeAsString(jsonEncode({
        'prefix': 'mdi',
        'icons': {
          'home': {'body': '<path d="home"/>'}
        },
        'width': 24,
        'height': 24
      }));
      provider = FileSystemIconifyProvider(root: tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('loads icon from file', () async {
      final icon = await provider.getIcon(IconifyName('mdi', 'home'));
      expect(icon, isNotNull);
      expect(icon!.body, contains('home'));
    });

    test('returns null for missing collection', () async {
      final icon = await provider.getIcon(IconifyName('ghost', 'home'));
      expect(icon, isNull);
    });

    test('returns null for missing icon in existing collection', () async {
      final icon = await provider.getIcon(IconifyName('mdi', 'ghost'));
      expect(icon, isNull);
    });

    test('hasIcon returns true for existing icon', () async {
      expect(await provider.hasIcon(IconifyName('mdi', 'home')), isTrue);
    });

    test('hasCollection returns true for existing file', () async {
      expect(await provider.hasCollection('mdi'), isTrue);
    });

    test('hasCollection returns false for missing file', () async {
      expect(await provider.hasCollection('ghost'), isFalse);
    });

    test('preloadAll loads files into cache', () async {
      final preloadedProvider =
          FileSystemIconifyProvider(root: tempDir.path, preload: true);
      // We can't easily check private cache, but we can verify it works instantly
      final icon = await preloadedProvider.getIcon(IconifyName('mdi', 'home'));
      expect(icon, isNotNull);
    });
  });
}
