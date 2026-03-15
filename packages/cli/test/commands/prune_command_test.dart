import 'dart:convert';
import 'dart:io';

import 'package:iconify_sdk_cli/src/cli_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockProgress extends Mock implements Progress {}

void main() {
  group('PruneCommand', () {
    late Directory tempDir;
    late Logger logger;
    late IconifyCommandRunner runner;
    late Progress progress;
    late String originalCwd;

    setUp(() async {
      originalCwd = Directory.current.path;
      tempDir = await Directory.systemTemp.createTemp('iconify_prune_test_');

      // Setup iconify.yaml
      await File(p.join(tempDir.path, 'iconify.yaml')).writeAsString('''
sets:
  - mdi:*
data_dir: assets/iconify
output: lib/icons.g.dart
''');

      // Setup used_icons.json
      final cacheDir = Directory(p.join(tempDir.path, 'assets', 'iconify'));
      await cacheDir.create(recursive: true);
      await File(p.join(tempDir.path, 'assets', 'iconify', 'used_icons.json'))
          .writeAsString(jsonEncode({
        'schemaVersion': 1,
        'icons': {
          'mdi:home': {'body': '<path/>'},
          'mdi:account': {'body': '<path/>'},
        }
      }));

      // Setup lib/ directory
      await Directory(p.join(tempDir.path, 'lib')).create(recursive: true);

      logger = MockLogger();
      progress = MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);

      runner = IconifyCommandRunner(logger: logger);
      Directory.current = tempDir;
    });

    tearDown(() async {
      Directory.current = originalCwd;
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('prunes stale icons with confirmation', () async {
      // Use only mdi:home in source
      await File(p.join(tempDir.path, 'lib', 'main.dart'))
          .writeAsString("IconifyIcon('mdi:home')");

      when(() =>
              logger.confirm(any(), defaultValue: any(named: 'defaultValue')))
          .thenReturn(true);

      final result = await runner.run(['prune']);

      expect(result, equals(ExitCode.success.code));

      final cacheFile =
          File(p.join(tempDir.path, 'assets', 'iconify', 'used_icons.json'));
      final cacheJson =
          jsonDecode(await cacheFile.readAsString()) as Map<String, dynamic>;
      final icons = cacheJson['icons'] as Map<String, dynamic>;

      expect(icons.containsKey('mdi:home'), isTrue);
      expect(icons.containsKey('mdi:account'), isFalse);
      expect(icons.length, equals(1));
    });

    test('respects --force flag', () async {
      await File(p.join(tempDir.path, 'lib', 'main.dart'))
          .writeAsString("IconifyIcon('mdi:home')");

      final result = await runner.run(['prune', '--force']);

      expect(result, equals(ExitCode.success.code));
      verifyNever(() =>
          logger.confirm(any(), defaultValue: any(named: 'defaultValue')));

      final cacheFile =
          File(p.join(tempDir.path, 'assets', 'iconify', 'used_icons.json'));
      final cacheJson =
          jsonDecode(await cacheFile.readAsString()) as Map<String, dynamic>;
      expect((cacheJson['icons'] as Map<String, dynamic>).length, equals(1));
    });

    test('respects --dry-run flag', () async {
      await File(p.join(tempDir.path, 'lib', 'main.dart'))
          .writeAsString("IconifyIcon('mdi:home')");

      final result = await runner.run(['prune', '--dry-run']);

      expect(result, equals(ExitCode.success.code));

      final cacheFile =
          File(p.join(tempDir.path, 'assets', 'iconify', 'used_icons.json'));
      final cacheJson =
          jsonDecode(await cacheFile.readAsString()) as Map<String, dynamic>;
      expect((cacheJson['icons'] as Map<String, dynamic>).length,
          equals(2)); // No icons removed
    });

    test('completes with message if nothing to prune', () async {
      await File(p.join(tempDir.path, 'lib', 'main.dart'))
          .writeAsString("IconifyIcon('mdi:home'), IconifyIcon('mdi:account')");

      final result = await runner.run(['prune']);

      expect(result, equals(ExitCode.success.code));
      verify(() =>
              progress.complete(any(that: contains('No stale icons found'))))
          .called(1);
    });
  });
}
