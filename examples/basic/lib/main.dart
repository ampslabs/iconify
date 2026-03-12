import 'package:flutter/material.dart';
import 'package:iconify_sdk/iconify_sdk.dart';

void main() {
  runApp(
    const IconifyApp(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BasicExample(),
      ),
    ),
  );
}

class BasicExample extends StatelessWidget {
  const BasicExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iconify Basic Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Simple Iconify Usage'),
            const SizedBox(height: 20),

            // Default size and color
            IconifyIcon('mdi:home'),

            const SizedBox(height: 20),

            // Custom size and color
            const IconifyIcon.name(
              IconifyName('lucide', 'rocket'),
              size: 64,
              color: Colors.deepPurple,
            ),

            const SizedBox(height: 20),

            // Multi-color icon
            IconifyIcon('logos:flutter', size: 48),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: () {},
              icon: IconifyIcon('tabler:settings', size: 20),
              label: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
