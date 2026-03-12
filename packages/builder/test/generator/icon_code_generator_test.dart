import 'package:iconify_sdk_builder/src/generator/icon_code_generator.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('IconCodeGenerator', () {
    test('generates valid code structure', () {
      final names = {'mdi:home', 'lucide:rocket'};
      final data = {
        'mdi:home': const IconifyIconData(
            body: '<path d="home"/>', width: 24, height: 24),
        'lucide:rocket': const IconifyIconData(
            body: '<path d="rocket"/>', width: 32, height: 32),
      };

      final output = IconCodeGenerator.generate(
        usedIconNames: names,
        iconDataMap: data,
      );

      expect(output, contains('// GENERATED CODE'));
      expect(output, contains('class IconsMdi'));
      expect(output, contains('class IconsLucide'));
      expect(output, contains('static const home = IconifyIconData'));
      expect(output, contains('static const rocket = IconifyIconData'));
      expect(output, contains('void initGeneratedIcons'));
      expect(output,
          contains("provider.putIcon(const IconifyName('mdi', 'home')"));
    });

    test('handles kebab-case names', () {
      final names = {'mdi:arrow-right'};
      final data = {
        'mdi:arrow-right':
            const IconifyIconData(body: '', width: 24, height: 24),
      };

      final output = IconCodeGenerator.generate(
        usedIconNames: names,
        iconDataMap: data,
      );

      expect(output, contains('static const arrowRight ='));
    });
  });
}
