// This example shows basic usage of the iconify_sdk_core package.
// ignore_for_file: avoid_print

import 'package:iconify_sdk_core/iconify_sdk_core.dart';

void main() async {
  // 1. Setup a provider (In-memory for this simple example)
  final provider = MemoryIconifyProvider();

  // 2. Add some icon data (usually this would be loaded from a file or network)
  final homeName = IconifyName.parse('mdi:home');
  provider.putIcon(
    homeName,
    const IconifyIconData(
      body: '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>',
    ),
  );

  // 3. Resolve icon data
  final iconData = await provider.getIcon(homeName);

  if (iconData != null) {
    // 4. Generate SVG string
    final svg = iconData.toSvgString(color: '#1a73e8', size: 24);
    print('Generated SVG for mdi:home:');
    print(svg);
  }
}
