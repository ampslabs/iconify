
import 'package:mason_logger/mason_logger.dart';

import 'base_command.dart';

class SyncCommand extends BaseCommand {
  SyncCommand({required super.logger}) {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Force re-download even if files exist and SHA matches.',
      negatable: false,
    );
    argParser.addOption(
      'collections',
      abbr: 'c',
      help: 'Comma-separated list of collections to sync.',
    );
  }

  @override
  String get name => 'sync';

  @override
  String get description => 'Sync icon collections from GitHub raw source.';

  @override
  Future<int> run() async {
    final config = await ensureConfig();
    if (config == null) return ExitCode.config.code;

    final Set<String> prefixes = {};

    final collectionsOverride = argResults?['collections'] as String?;
    if (collectionsOverride != null) {
      prefixes.addAll(collectionsOverride.split(',').map((s) => s.trim()));
    } else {
      for (final set in config.sets) {
        final prefix = set.split(':').first;
        prefixes.add(prefix);
      }
    }

    if (prefixes.isEmpty) {
      logger.warn('No collections to sync.');
      return ExitCode.success.code;
    }

    final success = await runSync(config, prefixes: prefixes.toList());
    return success ? ExitCode.success.code : ExitCode.software.code;
  }
}
