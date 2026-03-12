import 'dart:io';

import 'package:iconify_sdk_cli/src/cli_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

void main() {
  group('CLI Integration', () {
    late Directory tempDir;
    late Logger logger;
    late IconifyCommandRunner runner;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('iconify_cli_test_');
      logger = Logger();
      runner = IconifyCommandRunner(logger: logger);
      Directory.current = tempDir;
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('full workflow: init -> sync -> doctor -> generate', () async {
      // 1. Init (using default answers)
      // Note: We can't easily mock stdin for logger.prompt here,
      // so we manually create the file for this integration test.
      final configFile = File('iconify.yaml');
      await configFile.writeAsString('''
sets:
  - mdi:*
data_dir: assets/iconify
output: lib/icons.g.dart
''');

      expect(configFile.existsSync(), isTrue);

      // 2. Sync (Mocking real network might be hard, but let's try a real sync for mdi small)
      // Actually, for a pure unit/integration test, we should mock the sync logic
      // but let's verify the runner executes it.
      final syncResult = await runner.run(['sync', '--collections', 'mdi']);
      expect(syncResult, equals(ExitCode.success.code));

      final mdiFile = File('assets/iconify/mdi.json');
      expect(mdiFile.existsSync(), isTrue);

      // 3. Doctor
      final doctorResult = await runner.run(['doctor']);
      expect(doctorResult, equals(ExitCode.success.code));

      // 4. Generate
      // Create a dummy source file
      await Directory('lib').create();
      await File('lib/app.dart')
          .writeAsString("const icon = IconifyIcon('mdi:home');");

      final genResult = await runner.run(['generate']);
      expect(genResult, equals(ExitCode.success.code));

      final generatedFile = File('lib/icons.g.dart');
      expect(generatedFile.existsSync(), isTrue);
      expect(await generatedFile.readAsString(), contains('class IconsMdi'));
    });
  });
}
