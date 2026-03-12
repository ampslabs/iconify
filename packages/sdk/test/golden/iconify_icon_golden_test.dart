import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconify_sdk/iconify_sdk.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

void main() {
  group('IconifyIcon Golden Tests', () {
    late MemoryIconifyProvider provider;

    final monoHome = const IconifyName('test', 'home');
    final monoHomeData = const IconifyIconData(
      body:
          '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z" fill="currentColor"/>',
    );

    final multiColor = const IconifyName('test', 'multi');
    final multiColorData = const IconifyIconData(
      body:
          '<circle cx="12" cy="12" r="10" fill="red"/><circle cx="12" cy="12" r="5" fill="blue"/>',
    );

    setUp(() {
      provider = MemoryIconifyProvider();
      provider.putIcon(monoHome, monoHomeData);
      provider.putIcon(multiColor, multiColorData);
    });

    goldenTest(
      'IconifyIcon variations',
      fileName: 'iconify_icon_variations',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Monochrome default',
            child: IconifyScope(
              provider: provider,
              child: IconifyIcon('test:home'),
            ),
          ),
          GoldenTestScenario(
            name: 'Monochrome colored',
            child: IconifyScope(
              provider: provider,
              child: IconifyIcon('test:home', color: Colors.blue),
            ),
          ),
          GoldenTestScenario(
            name: 'Multicolor',
            child: IconifyScope(
              provider: provider,
              child: IconifyIcon('test:multi'),
            ),
          ),
          GoldenTestScenario(
            name: 'Custom size',
            child: IconifyScope(
              provider: provider,
              child: IconifyIcon('test:home', size: 48),
            ),
          ),
          GoldenTestScenario(
            name: 'Error state',
            child: IconifyScope(
              provider: provider,
              child: IconifyIcon('test:missing'),
            ),
          ),
        ],
      ),
    );
  });
}
