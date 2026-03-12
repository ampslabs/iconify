import 'package:iconify_sdk_builder/src/config/iconify_build_config.dart';
import 'package:test/test.dart';

void main() {
  group('IconifyBuildConfig', () {
    test('parses empty string to defaults', () {
      final config = IconifyBuildConfig.fromYaml('');
      expect(config.sets, isEmpty);
      expect(config.output, 'lib/icons.g.dart');
      expect(config.dataDir, 'assets/iconify');
      expect(config.mode, 'auto');
      expect(config.licensePolicy, 'warn');
      expect(config.customSets, isEmpty);
      expect(config.failOnMissing, isFalse);
    });

    test('parses full config matching spec', () {
      final yaml = '''
sets:
  - mdi:*
  - lucide:home
output: lib/src/icons.dart
data_dir: custom_assets
mode: offline
license_policy: strict
custom_sets:
  - data/my_icons.json
fail_on_missing: true
      ''';
      final config = IconifyBuildConfig.fromYaml(yaml);
      expect(config.sets, ['mdi:*', 'lucide:home']);
      expect(config.output, 'lib/src/icons.dart');
      expect(config.dataDir, 'custom_assets');
      expect(config.mode, 'offline');
      expect(config.licensePolicy, 'strict');
      expect(config.customSets, ['data/my_icons.json']);
      expect(config.failOnMissing, isTrue);
    });

    test('throws FormatException on invalid root', () {
      expect(() => IconifyBuildConfig.fromYaml('just a string'),
          throwsFormatException);
    });
  });
}
