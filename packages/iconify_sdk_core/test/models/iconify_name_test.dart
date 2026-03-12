import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('IconifyName', () {
    group('parse — valid inputs', () {
      test('parses simple prefix:name', () {
        final name = IconifyName.parse('mdi:home');
        expect(name.prefix, 'mdi');
        expect(name.iconName, 'home');
      });

      test('parses name with hyphens', () {
        final name = IconifyName.parse('mdi:arrow-left-circle');
        expect(name.iconName, 'arrow-left-circle');
      });

      test('parses prefix with hyphens', () {
        final name = IconifyName.parse('fluent-emoji:home');
        expect(name.prefix, 'fluent-emoji');
      });

      test('parses single-char prefix and name', () {
        final name = IconifyName.parse('a:b');
        expect(name.prefix, 'a');
        expect(name.iconName, 'b');
      });

      test('parses name with digits', () {
        final name = IconifyName.parse('mdi:format-h1');
        expect(name.iconName, 'format-h1');
      });

      test('toString returns canonical form', () {
        expect(IconifyName.parse('mdi:home').toString(), 'mdi:home');
      });
    });

    group('parse — invalid inputs', () {
      test('throws on missing colon', () {
        expect(
          () => IconifyName.parse('mdi-home'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('throws on empty prefix', () {
        expect(
          () => IconifyName.parse(':home'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('throws on empty name', () {
        expect(
          () => IconifyName.parse('mdi:'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('throws on double colon', () {
        expect(
          () => IconifyName.parse('mdi:home:extra'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('throws on uppercase prefix', () {
        expect(
          () => IconifyName.parse('MDI:home'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('throws on uppercase name', () {
        expect(
          () => IconifyName.parse('mdi:Home'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('throws on leading hyphen in prefix', () {
        expect(
          () => IconifyName.parse('-mdi:home'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('throws on trailing hyphen in name', () {
        expect(
          () => IconifyName.parse('mdi:home-'),
          throwsA(isA<InvalidIconNameException>()),
        );
      });
    });

    group('tryParse', () {
      test('returns name for valid input', () {
        expect(IconifyName.tryParse('mdi:home'), isNotNull);
      });

      test('returns null for invalid input', () {
        expect(IconifyName.tryParse('mdi-home'), isNull);
      });
    });

    group('equality and hashing', () {
      test('equal for same prefix and name', () {
        expect(
          IconifyName('mdi', 'home'),
          equals(IconifyName('mdi', 'home')),
        );
      });

      test('not equal for different prefix', () {
        expect(
          IconifyName('mdi', 'home'),
          isNot(equals(IconifyName('lucide', 'home'))),
        );
      });

      test('not equal for different name', () {
        expect(
          IconifyName('mdi', 'home'),
          isNot(equals(IconifyName('mdi', 'settings'))),
        );
      });

      test('same hashCode for equal names', () {
        expect(
          IconifyName('mdi', 'home').hashCode,
          equals(IconifyName('mdi', 'home').hashCode),
        );
      });

      test('can be used as Map key', () {
        final map = {IconifyName('mdi', 'home'): 'value'};
        expect(map[IconifyName('mdi', 'home')], 'value');
      });

      test('can be used in Set', () {
        final set = {IconifyName('mdi', 'home'), IconifyName('mdi', 'home')};
        expect(set.length, 1);
      });
    });

    group('const construction', () {
      test('const constructor works', () {
        const name = IconifyName('mdi', 'home');
        expect(name.prefix, 'mdi');
      });
    });
  });
}
