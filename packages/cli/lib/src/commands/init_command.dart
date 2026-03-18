import 'package:mason_logger/mason_logger.dart';

import 'base_command.dart';

class InitCommand extends BaseCommand {
  InitCommand({required super.logger}) {
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

  @override
  Future<int> run() async {
    await runInit();
    return ExitCode.success.code;
  }
}
