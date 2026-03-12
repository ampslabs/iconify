import 'dart:io';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('IconifyJsonParser', () {
    group('parseCollectionString', () {
      test('parses valid minimal collection', () {
        const json = '''
        {
          "prefix": "test",
          "width": 24,
          "height": 24,
          "icons": {
            "home": { "body": "<path d='M10 20v-6h4v6'/>" }
          }
        }
        ''';
        final result = IconifyJsonParser.parseCollectionString(json);
        expect(result.prefix, 'test');
        expect(result.icons, hasLength(1));
        expect(result.icons['home']?.body, contains('M10 20'));
      });

      test('inherits default width/height when not specified per-icon', () {
        const json = '''
        {
          "prefix": "test",
          "width": 32,
          "height": 32,
          "icons": {
            "icon1": { "body": "<path/>" }
          }
        }
        ''';
        final result = IconifyJsonParser.parseCollectionString(json);
        expect(result.icons['icon1']?.width, 32);
        expect(result.icons['icon1']?.height, 32);
      });

      test('icon-level width/height overrides collection default', () {
        const json = '''
        {
          "prefix": "test",
          "width": 24,
          "height": 24,
          "icons": {
            "wide": { "body": "<path/>", "width": 48, "height": 24 }
          }
        }
        ''';
        final result = IconifyJsonParser.parseCollectionString(json);
        expect(result.icons['wide']?.width, 48);
        expect(result.icons['wide']?.height, 24);
      });

      test('parses aliases', () {
        const json = '''
        {
          "prefix": "test",
          "width": 24,
          "height": 24,
          "icons": {
            "home": { "body": "<path/>" }
          },
          "aliases": {
            "home-solid": { "parent": "home" }
          }
        }
        ''';
        final result = IconifyJsonParser.parseCollectionString(json);
        expect(result.aliases, hasLength(1));
        expect(result.aliases['home-solid']?.parent, 'home');
      });

      test('throws on missing prefix', () {
        const json = '{"icons": {"a": {"body": "<path/>"}}}';
        expect(
          () => IconifyJsonParser.parseCollectionString(json),
          throwsA(isA<IconifyParseException>()),
        );
      });

      test('throws on missing icons field', () {
        const json = '{"prefix": "test"}';
        expect(
          () => IconifyJsonParser.parseCollectionString(json),
          throwsA(isA<IconifyParseException>()),
        );
      });

      test('throws on invalid JSON', () {
        expect(
          () => IconifyJsonParser.parseCollectionString('not json at all'),
          throwsA(isA<IconifyParseException>()),
        );
      });
    });

    group('getIcon with alias resolution', () {
      const json = '''
      {
        "prefix": "test",
        "width": 24,
        "height": 24,
        "icons": {
          "home": { "body": "<path d='home'/>" }
        },
        "aliases": {
          "home-alias": { "parent": "home" }
        }
      }
      ''';

      test('finds direct icon', () {
        final collection = IconifyJsonParser.parseCollectionString(json);
        expect(collection.getIcon('home'), isNotNull);
      });

      test('resolves alias to parent icon', () {
        final collection = IconifyJsonParser.parseCollectionString(json);
        final result = collection.getIcon('home-alias');
        expect(result?.body, contains('home'));
      });

      test('returns null for nonexistent icon', () {
        final collection = IconifyJsonParser.parseCollectionString(json);
        expect(collection.getIcon('does-not-exist'), isNull);
      });
    });

    group('fixture files', () {
      test('parses mdi_fixture.json', () {
        final content =
            File('test/fixtures/mdi_fixture.json').readAsStringSync();
        final result = IconifyJsonParser.parseCollectionString(content);
        expect(result.prefix, 'mdi');
        expect(result.icons, isNotEmpty);
      });

      test('parses alias_chain_fixture.json', () {
        final content =
            File('test/fixtures/alias_chain_fixture.json').readAsStringSync();
        final collection = IconifyJsonParser.parseCollectionString(content);

        // Direct icon
        expect(collection.getIcon('base-icon'), isNotNull);

        // Depth-1 alias
        expect(collection.getIcon('level1'), isNotNull);

        // Depth-2 alias
        expect(collection.getIcon('level2'), isNotNull);

        // Depth-3 alias with width override
        final level3 = collection.getIcon('level3');
        expect(level3, isNotNull);
        expect(level3!.width, 32);

        // Circular alias should throw
        expect(
          () => collection.getIcon('circular-a'),
          throwsA(isA<CircularAliasException>()),
        );
      });
    });
  });
}
