import 'dart:convert';
import 'dart:io';

import 'package:iconify_sdk_cli/src/cli_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}
class _MockProgress extends Mock implements Progress {}

void main() {
  group('PruneCommand', () {
    late Directory tempDir;
    late Logger logger;
    late IconifyCommandRunner runner;
    late String originalCwd;

    setUp(() async {
      originalCwd = Directory.current.path;
      tempDir = await Directory.systemTemp.createTemp('iconify_prune_test_');
      logger = _MockLogger();
      runner = IconifyCommandRunner(logger: logger);

      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      // Mock confirmation to return true by default
      when(() => logger.confirm(any(), defaultValue: any(named: 'defaultValue')))
          .thenReturn(true);

      // Create dummy iconify.yaml
      File(p.join(tempDir.path, 'iconify.yaml')).writeAsStringSync('''
sets:
  - mdi:*
data_dir: assets/iconify
''');

      // Create dummy used_icons.json with one stale icon
      final dataDir = Directory(p.join(tempDir.path, 'assets', 'iconify'))
        ..createSync(recursive: true);
      File(p.join(dataDir.path, 'used_icons.json')).writeAsStringSync(jsonEncode({
        'icons': {
          'mdi:home': {
            'body': '<path/>',
            'lastUsed': '2023-01-01T00:00:00Z',
            'source': 'added',
          }
        }
      }));

      // Create a dummy lib/ file that DOES NOT use the icon
      Directory(p.join(tempDir.path, 'lib')).createSync();
      File(p.join(tempDir.path, 'lib', 'main.dart'))
          .writeAsStringSync('void main() {}');

      Directory.current = tempDir;
    });

    tearDown(() async {
      Directory.current = originalCwd;
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('prunes stale icons with confirmation', () async {
      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);

      final result = await runner.run(['prune']);

      expect(result, equals(ExitCode.success.code));
      verify(() => logger.confirm(any(), defaultValue: any(named: 'defaultValue'))).called(1);
      
      final cacheFile = File('assets/iconify/used_icons.json');
      final data = jsonDecode(cacheFile.readAsStringSync()) as Map;
      final icons = data['icons'] as Map;
      expect(icons.containsKey('mdi:home'), isFalse);
    });

    test('respects --dry-run flag', () async {
      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);

      final result = await runner.run(['prune', '--dry-run']);

      expect(result, equals(ExitCode.success.code));
      // File should NOT be changed
      final cacheFile = File('assets/iconify/used_icons.json');
      final data = jsonDecode(cacheFile.readAsStringSync()) as Map;
      final icons = data['icons'] as Map;
      expect(icons.containsKey('mdi:home'), isTrue);
    });

    test('completes if nothing to prune', () async {
      // Update lib/main.dart to USE the icon
      File('lib/main.dart').writeAsStringSync("final icon = 'mdi:home';");

      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);

      final result = await runner.run(['prune']);

      expect(result, equals(ExitCode.success.code));
    });
  });
}
