import 'dart:typed_data';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryIconFormat', () {
    const collection = ParsedCollection(
      prefix: 'test',
      info: IconifyCollectionInfo(
        prefix: 'test',
        name: 'Test Collection',
        totalIcons: 2,
        author: 'Author',
        license: IconifyLicense(
          title: 'MIT',
          spdx: 'MIT',
          requiresAttribution: false,
        ),
      ),
      icons: {
        'home':
            IconifyIconData(body: '<path d="home"/>', width: 24, height: 24),
        'user': IconifyIconData(
            body: '<path d="user"/>',
            width: 20,
            height: 20,
            rotate: 1,
            hFlip: true),
      },
      aliases: {
        'profile': AliasEntry(parent: 'user', vFlip: true),
      },
      defaultWidth: 24,
      defaultHeight: 24,
    );

    test('encodes and decodes collection round-trip', () {
      final encoded = BinaryIconFormat.encode(collection);
      final decoded = BinaryIconFormat.decode(encoded);

      expect(decoded.prefix, equals(collection.prefix));
      expect(decoded.info.name, equals(collection.info.name));
      expect(decoded.info.totalIcons, equals(collection.info.totalIcons));
      expect(decoded.info.author, equals(collection.info.author));
      expect(
          decoded.info.license?.title, equals(collection.info.license?.title));

      expect(decoded.iconCount, equals(collection.iconCount));
      expect(
          decoded.icons['home']?.body, equals(collection.icons['home']?.body));
      expect(decoded.icons['home']?.width,
          equals(collection.icons['home']?.width));
      expect(decoded.icons['user']?.rotate,
          equals(collection.icons['user']?.rotate));
      expect(decoded.icons['user']?.hFlip,
          equals(collection.icons['user']?.hFlip));

      expect(decoded.aliasCount, equals(collection.aliasCount));
      expect(decoded.aliases['profile']?.parent,
          equals(collection.aliases['profile']?.parent));
      expect(decoded.aliases['profile']?.vFlip,
          equals(collection.aliases['profile']?.vFlip));
    });

    test('decodeIcon extracts single icon without full decode', () {
      final encoded = BinaryIconFormat.encode(collection);

      final home = BinaryIconFormat.decodeIcon(encoded, 'home');
      expect(home, isNotNull);
      expect(home?.body, equals('<path d="home"/>'));

      final user = BinaryIconFormat.decodeIcon(encoded, 'user');
      expect(user, isNotNull);
      expect(user?.body, equals('<path d="user"/>'));
      expect(user?.rotate, equals(1));

      final missing = BinaryIconFormat.decodeIcon(encoded, 'missing');
      expect(missing, isNull);
    });

    test('throws FormatException on invalid magic bytes', () {
      final invalid = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      expect(() => BinaryIconFormat.decode(invalid), throwsFormatException);
    });
  });
}
