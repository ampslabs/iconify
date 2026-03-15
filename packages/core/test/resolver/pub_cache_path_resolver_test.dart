import 'dart:io';

import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('PubCachePathResolver', () {
    test('resolves a package path in the current workspace', () async {
      final path =
          await PubCachePathResolver.resolvePackagePath('iconify_sdk_core');

      expect(path, isNotNull);
      // It should point to the packages/core directory in this repo
      expect(path, contains('packages/core'));
      expect(Directory(path!).existsSync(), isTrue);
    });

    test('returns null for nonexistent package', () async {
      final path = await PubCachePathResolver.resolvePackagePath(
          'nonexistent_package_12345');
      expect(path, isNull);
    });

    test('caching works', () async {
      final path1 =
          await PubCachePathResolver.resolvePackagePath('iconify_sdk_core');
      final path2 =
          await PubCachePathResolver.resolvePackagePath('iconify_sdk_core');

      expect(path1, same(path2));
    });
  });
}
