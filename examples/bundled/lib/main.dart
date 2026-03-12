import 'package:flutter/material.dart';
import 'package:iconify_sdk/iconify_sdk.dart';
// Note: In a real project, you would run build_runner to generate this file.
// For this example, we provide a mock/placeholder of what it would look like.
import 'icons.g.dart';

void main() {
  // 1. Initialize the memory provider with our bundled icons
  final memoryProvider = MemoryIconifyProvider();
  initGeneratedIcons(memoryProvider);

  runApp(
    IconifyApp(
      config: IconifyConfig(
        // 2. Prioritize our bundled icons
        customProviders: [memoryProvider],
        // 3. Optional: Use offline mode to guarantee zero network
        mode: IconifyMode.offline,
      ),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BundledExample(),
      ),
    ),
  );
}

class BundledExample extends StatelessWidget {
  const BundledExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iconify Bundled Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Loading from Generated Constants (Offline)'),
            const SizedBox(height: 20),

            // This is loading from lib/icons.g.dart
            const IconifyIcon('mdi:account', size: 80, color: Colors.blue),

            const SizedBox(height: 20),

            const Text('Zero Network Latency'),
          ],
        ),
      ),
    );
  }
}
