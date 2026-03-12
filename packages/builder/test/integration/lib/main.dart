// These imports are used for integration test fixtures and are not direct dependencies.
// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:iconify_sdk/iconify_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconifyIcon('mdi:home'),
        IconifyIcon('lucide:rocket'),
        IconifyIcon('tabler:star'),
      ],
    );
  }
}
