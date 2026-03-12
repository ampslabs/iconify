import 'package:iconify_sdk_builder/src/scanner/icon_name_scanner.dart';
import 'package:test/test.dart';

void main() {
  group('IconNameScanner', () {
    test('detects simple IconifyIcon usage', () {
      const code = "final icon = IconifyIcon('mdi:home');";
      final scanner = IconNameScanner()..scan(code);
      expect(scanner.iconNames, contains('mdi:home'));
    });

    test('detects double quotes', () {
      const code = 'final icon = IconifyIcon("mdi:home");';
      final scanner = IconNameScanner()..scan(code);
      expect(scanner.iconNames, contains('mdi:home'));
    });

    test('detects multiple icons', () {
      const code = """
        final a = IconifyIcon('mdi:home');
        final b = IconifyIcon('lucide:rocket');
      """;
      final scanner = IconNameScanner()..scan(code);
      expect(scanner.iconNames, containsAll(['mdi:home', 'lucide:rocket']));
    });

    test('detects IconifyName usage', () {
      const code = "final name = IconifyName('mdi', 'home');";
      final scanner = IconNameScanner()..scan(code);
      expect(scanner.iconNames, contains('mdi:home'));
    });

    test('ignores unrelated strings', () {
      const code = "final text = 'some:text';";
      final scanner = IconNameScanner()..scan(code);
      expect(scanner.iconNames, isEmpty);
    });

    test('is case insensitive for class names', () {
      const code = "iconifyicon('mdi:home')";
      final scanner = IconNameScanner()..scan(code);
      expect(scanner.iconNames, contains('mdi:home'));
    });
  });
}
