import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('IconifyJsonParser Fuzz Testing', () {
    test('throws IconifyParseException on invalid JSON syntax', () {
      const inputs = [
        '{',
        '{"prefix": "mdi",}', // Trailing comma (invalid in standard JSON)
        'not json',
        '',
      ];

      for (final input in inputs) {
        expect(
          () => IconifyJsonParser.parseCollectionString(input),
          throwsA(isA<IconifyParseException>()),
          reason: 'Input: $input',
        );
      }
    });

    test('throws IconifyParseException on missing required fields', () {
      const inputs = [
        '{}', // Empty object
        '{"icons": {}}', // Missing prefix
        '{"prefix": "mdi"}', // Missing icons
      ];

      for (final input in inputs) {
        expect(
          () => IconifyJsonParser.parseCollectionString(input),
          throwsA(isA<IconifyParseException>()),
          reason: 'Input: $input',
        );
      }
    });

    test('throws IconifyParseException on wrong data types', () {
      const inputs = [
        '{"prefix": 123, "icons": {}}', // Prefix is int
        '{"prefix": "mdi", "icons": []}', // Icons is list
        '{"prefix": "mdi", "icons": {"home": []}}', // Single icon is list
        '{"prefix": "mdi", "icons": {"home": {"body": 123}}}', // Body is int
      ];

      for (final input in inputs) {
        expect(
          () => IconifyJsonParser.parseCollectionString(input),
          throwsA(isA<IconifyParseException>()),
          reason: 'Input: $input',
        );
      }
    });

    test('handles deeply nested circular aliases without crashing', () {
      const json = {
        'prefix': 'test',
        'icons': {
          'base': {'body': '<path/>'}
        },
        'aliases': {
          'a': {'parent': 'b'},
          'b': {'parent': 'a'},
        }
      };

      final collection = IconifyJsonParser.parseCollection(json);

      // Requesting a circular alias should throw CircularAliasException, not crash
      expect(
        () => collection.getIcon('a'),
        throwsA(isA<CircularAliasException>()),
      );
    });

    test('handles extremely large number of aliases', () {
      final icons = {
        'base': {'body': '<path/>'}
      };
      final aliases = <String, dynamic>{};

      for (var i = 0; i < 1000; i++) {
        aliases['alias-$i'] = {'parent': 'base'};
      }

      final json = {
        'prefix': 'test',
        'icons': icons,
        'aliases': aliases,
      };

      final collection = IconifyJsonParser.parseCollection(json);
      expect(collection.aliasCount, 1000);
      expect(collection.getIcon('alias-999'), isNotNull);
    });
  });
}
