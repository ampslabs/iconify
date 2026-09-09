// A minimal Flutter app demonstrating how to use iconify_sdk.
//
// The SDK bundles a small starter icon set (mdi, lucide, tabler, heroicons),
// so this example renders icons right away without any configuration.
//
// Run it with:
//   flutter create . --platforms=ios,android,macos,linux,windows,web
//   flutter run
//
// Then run `dart run iconify_sdk_cli:iconify` to learn how to bundle your
// own icon sets and enable fully-offline rendering in production.

import 'package:flutter/material.dart';
import 'package:iconify_sdk/iconify_sdk.dart';

void main() {
  runApp(
    const IconifyApp(
      child: MaterialApp(
        title: 'Iconify SDK Example',
        debugShowCheckedModeBanner: false,
        home: IconifyExampleScreen(),
      ),
    ),
  );
}

/// The main screen of the example app.
class IconifyExampleScreen extends StatelessWidget {
  /// Creates the example screen.
  const IconifyExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iconify SDK Example')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Icons rendered from the bundled starter set:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconifyIcon('mdi:home', size: 48),
                const SizedBox(width: 24),
                IconifyIcon('mdi:account', size: 48, color: Colors.blue),
                const SizedBox(width: 24),
                IconifyIcon('lucide:heart', size: 48, color: Colors.red),
                const SizedBox(width: 24),
                IconifyIcon('tabler:star', size: 48, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Icons scale and recolor like any Flutter widget:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            IconifyIcon('mdi:home', size: 96, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
