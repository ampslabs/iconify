import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

class InitCommand extends Command<int> {
  InitCommand({required Logger logger}) : _logger = logger {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Overwrite existing iconify.yaml.',
      negatable: false,
    );
  }

  @override
  String get name => 'init';

  @override
  String get description => 'Initialize Iconify configuration in your project.';

  final Logger _logger;

  @override
  Future<int> run() async {
    final configFile = File('iconify.yaml');
    if (configFile.existsSync() && argResults?['force'] != true) {
      _logger.err('iconify.yaml already exists. Use --force to overwrite.');
      return ExitCode.software.code;
    }

    _logger.info('🚀 Initializing Iconify SDK...');

    // 1. Ask for initial sets
    final setsStr = _logger.prompt(
      'Which icon sets would you like to start with? (comma separated)',
      defaultValue: 'mdi,lucide',
    );
    final sets = setsStr
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // 2. Ask for data directory
    final dataDir = _logger.prompt(
      'Where should local icon snapshots be stored?',
      defaultValue: 'assets/iconify',
    );

    // 3. Ask for output path
    final output = _logger.prompt(
      'Where should the generated Dart code be written?',
      defaultValue: 'lib/icons.g.dart',
    );

    // 4. Generate YAML
    final yamlBuffer = StringBuffer();
    yamlBuffer.writeln('# Iconify SDK Configuration');
    yamlBuffer.writeln('# See docs at https://github.com/ampslabs/iconify');
    yamlBuffer.writeln();
    yamlBuffer.writeln('sets:');
    for (final s in sets) {
      yamlBuffer.writeln('  - $s:*');
    }
    yamlBuffer.writeln();
    yamlBuffer.writeln('data_dir: $dataDir');
    yamlBuffer.writeln('output: $output');
    yamlBuffer.writeln('mode: auto');
    yamlBuffer.writeln('license_policy: warn');
    yamlBuffer.writeln('fail_on_missing: false');

    await configFile.writeAsString(yamlBuffer.toString());

    // 5. Ensure data directory exists
    final dir = Directory(dataDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // 6. Create initial used_icons.json
    final cachePath = p.join(dataDir, 'used_icons.json');
    final cacheFile = File(cachePath);
    if (!cacheFile.existsSync()) {
      await cacheFile.writeAsString(
        '{"schemaVersion": 1, "generated": "${DateTime.now().toUtc().toIso8601String()}", "icons": {}}',
      );
    }

    _logger.success('✅ Created iconify.yaml');
    _logger.success('✅ Initialized $cachePath');
    _logger.info('\nNext steps:');
    _logger.info(
        '1. Run ${lightCyan.wrap('dart run iconify_sdk_cli sync')} to download icon data.');
    _logger
        .info('2. Add ${lightCyan.wrap('IconifyIcon')} widgets to your app.');
    _logger.info(
        '3. Run ${lightCyan.wrap('iconify prune')} to clean up stale icons.');

    return ExitCode.success.code;
  }
}
