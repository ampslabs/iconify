import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconify_sdk/iconify_sdk.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

void main() {
  group('IconifyIcon Golden Tests', () {
    final provider = MemoryIconifyProvider();

    const monoHome = IconifyName('test', 'home');
    const monoHomeData = IconifyIconData(
      body:
          '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z" fill="currentColor"/>',
    );

    const multiColor = IconifyName('test', 'multi');
    const multiColorData = IconifyIconData(
      body:
          '<circle cx="12" cy="12" r="10" fill="red"/><circle cx="12" cy="12" r="5" fill="blue"/>',
    );

    setUpAll(() {
      provider.putIcon(monoHome, monoHomeData);
      provider.putIcon(multiColor, multiColorData);
    });

    goldenTest(
      'IconifyIcon variations',
      fileName: 'iconify_icon_variations',
      builder: () => IconifyScope(
        provider: provider,
        child: GoldenTestGroup(
          children: [
            GoldenTestScenario(
              name: 'Monochrome default',
              child: IconifyIcon('test:home'),
            ),
            GoldenTestScenario(
              name: 'Monochrome colored',
              child: IconifyIcon('test:home', color: Colors.blue),
            ),
            GoldenTestScenario(
              name: 'Multicolor',
              child: IconifyIcon('test:multi'),
            ),
            GoldenTestScenario(
              name: 'Custom size',
              child: IconifyIcon('test:home', size: 48),
            ),
            GoldenTestScenario(
              name: 'Error state',
              child: IconifyIcon('test:missing'),
            ),
          ],
        ),
      ),
    );
  });
}
