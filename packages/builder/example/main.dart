// Shows how to use iconify_sdk_builder programmatically: scan Dart source
// code for icon names, then generate the optimized `icons.g.dart` content.
//
// Run it with:
//   dart run example/main.dart
//
// For the typical build_runner workflow, see the README in this directory.
// ignore_for_file: avoid_print

import 'package:iconify_sdk_builder/iconify_sdk_builder.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

/// Example source that uses Iconify icons (as it would appear in your app).
const String _source = '''
  import 'package:flutter/material.dart';
  import 'package:iconify_sdk/iconify_sdk.dart';

  void main() {
    runApp(
      const IconifyApp(
        child: MaterialApp(home: IconifyIcon('mdi:home', size: 48)),
      ),
    );
  }
''';

void main() {
  // 1. Scan Dart source for icon references.
  final scanner = IconNameScanner()..scan(_source);
  final usedIconNames = scanner.iconNames;
  print('Icons detected in source: $usedIconNames');

  // 2. Generate the optimized Dart constants for the detected icons.
  //    (In a real project, icon data comes from the generated icon assets.)
  final generated = IconCodeGenerator.generate(
    usedIconNames: usedIconNames,
    iconDataMap: {
      'mdi:home': const IconifyIconData(
        body: '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>',
        width: 24,
        height: 24,
      ),
    },
  );
  print(generated);
}
