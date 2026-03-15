import 'package:args/command_runner.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:mason_logger/mason_logger.dart';

import 'commands/add_command.dart';
import 'commands/doctor_command.dart';
import 'commands/generate_command.dart';
import 'commands/init_command.dart';
import 'commands/licenses_command.dart';
import 'commands/prune_command.dart';
import 'commands/sync_command.dart';

class IconifyCommandRunner extends CommandRunner<int> {
  IconifyCommandRunner({Logger? logger})
      : _logger = logger ?? Logger(),
        super('iconify', 'CLI tool for managing Iconify icons in Flutter.') {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Enable verbose logging.',
      negatable: false,
    );

    addCommand(InitCommand(logger: _logger));
    addCommand(SyncCommand(logger: _logger));
    addCommand(GenerateCommand(logger: _logger));
    addCommand(DoctorCommand(logger: _logger));
    addCommand(LicensesCommand(logger: _logger));
    addCommand(PruneCommand(logger: _logger));
    addCommand(AddCommand(logger: _logger));
  }

  final Logger _logger;

  @override
  Future<int?> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);
      if (argResults['verbose'] == true) {
        _logger.level = Level.verbose;
      }
      return await runCommand(argResults);
    } on FormatException catch (e) {
      _logger.err(e.message);
      _logger.info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      _logger.err(e.message);
      _logger.info(e.usage);
      return ExitCode.usage.code;
    } on IconifyException catch (e) {
      _logger.err('Iconify Error: ${e.message}');
      return ExitCode.software.code;
    } catch (e, st) {
      _logger.err('Unexpected Error: $e');
      _logger.detail(st.toString());
      return ExitCode.software.code;
    }
  }
}
