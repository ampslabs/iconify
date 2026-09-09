import 'dart:async';
import 'package:alchemist/alchemist.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: true,
        diffThreshold: 0.002,
      ),
      ciGoldensConfig: CiGoldensConfig(
        enabled: true,
        diffThreshold: 0.002,
      ),
    ),
    run: testMain,
  );
}
