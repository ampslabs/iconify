import 'dart:io';
import 'package:iconify_sdk_cli/src/cli_runner.dart';

Future<void> main(List<String> args) async {
  exitCode = await IconifyCommandRunner().run(args) ?? 0;
}
