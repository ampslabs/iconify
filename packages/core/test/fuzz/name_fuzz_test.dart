import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('IconifyName Fuzz Testing', () {
    final invalidInputs = [
      '', // Empty
      ' ', // Whitespace only
      'mdi', // Missing colon
      'mdi:', // Missing name
      ':home', // Missing prefix
      'mdi:home:', // Trailing colon
      'mdi::home', // Double colon
      'MDI:home', // Uppercase prefix
      'mdi:Home', // Uppercase name
      'mdi:home ', // Trailing space
      ' mdi:home', // Leading space
      '-mdi:home', // Leading hyphen
      'mdi-:home', // Trailing hyphen in prefix
      'mdi:-home', // Leading hyphen in name
      'mdi:home-', // Trailing hyphen in name
      'mdi:home!', // Special character
      'mdi@home', // Special character instead of colon
      '🚀:home', // Emoji in prefix
      'mdi:🚀', // Emoji in name
      'mdi:home/path', // Path traversal attempt
      'mdi:home; DROP TABLE icons', // SQL injection attempt
      'mdi:home<script>', // XSS attempt
      'a' * 65 + ':home', // Prefix too long
      'mdi:${'a' * 65}', // Name too long
      'prefix_with_underscore:name', // Underscore not allowed
      'prefix:name_with_underscore', // Underscore not allowed
    ];

    for (final input in invalidInputs) {
      test('throws InvalidIconNameException for: "$input"', () {
        expect(
          () => IconifyName.parse(input),
          throwsA(isA<InvalidIconNameException>()),
        );
      });

      test('tryParse returns null for: "$input"', () {
        expect(IconifyName.tryParse(input), isNull);
      });
    }
  });
}
