import 'dart:async';
import 'package:flutter/cupertino.dart' show CupertinoApp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import '../config/iconify_config.dart';
import '../config/iconify_scope.dart';
import '../config/provider_chain_builder.dart';
import '../registry/starter_registry.dart';

/// A wrapper widget that initializes and provides the Iconify environment.
///
/// Place this at the root of your application, above [MaterialApp] or [CupertinoApp].
///
/// ```dart
/// void main() {
///   runApp(
///     const IconifyApp(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
class IconifyApp extends StatefulWidget {
  const IconifyApp({
    required this.child,
    super.key,
    this.config = const IconifyConfig(),
  });

  final Widget child;

  /// Global configuration for icon resolution and rendering.
  final IconifyConfig config;

  /// Starts preloading icon collections before the [IconifyApp] widget is built.
  ///
  /// This is an optional optimization that can be called in `main()` to
  /// reduce latency for the first icons rendered.
  ///
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await IconifyApp.preload(prefixes: ['mdi', 'lucide']);
  ///   runApp(const IconifyApp(child: MyApp()));
  /// }
  /// ```
  static Future<void> preload({List<String> prefixes = const []}) async {
    await StarterRegistry.instance.initialize(preloadPrefixes: prefixes);
  }

  @override
  State<IconifyApp> createState() => _IconifyAppState();
}

class _IconifyAppState extends State<IconifyApp> {
  IconifyProvider? _provider;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(IconifyApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config != oldWidget.config) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    // 1. Ensure starter registry is ready
    await StarterRegistry.instance
        .initialize(preloadPrefixes: widget.config.preloadPrefixes);

    // 2. Check for production bundle (Debug only)
    if (kDebugMode) {
      unawaited(_checkProductionBundle());
    }

    // 3. Build the provider chain based on config
    if (mounted) {
      setState(() {
        _provider = buildProviderChain(widget.config);
      });
    }
  }

  Future<void> _checkProductionBundle() async {
    final fileName =
        widget.config.compress ? 'used_icons.json.gz' : 'used_icons.json';
    final path = 'assets/iconify/$fileName';

    try {
      await rootBundle.load(path);
    } catch (_) {
      // Show a helpful warning in the console if the production bundle is missing.
      // ignore: avoid_print
      print(
          '\x1B[33m[Iconify SDK] ⚠️ WARNING: No production icon bundle found at $path.\x1B[0m');
      // Show installation instructions.
      // ignore: avoid_print
      print(
          '\x1B[33m[Iconify SDK] To optimize your app and enable offline support, install the CLI:\x1B[0m');
      // Show the command to activate the CLI.
      // ignore: avoid_print
      print(
          '\x1B[33m[Iconify SDK]   dart pub global activate iconify_sdk_cli\x1B[0m');
      // Show the header for the next command.
      // ignore: avoid_print
      print('\x1B[33m[Iconify SDK] Then run:\x1B[0m');
      // Show the generate command.
      // ignore: avoid_print
      print(
          '\x1B[33m[Iconify SDK]   iconify generate --compress --font\x1B[0m');
    }
  }

  @override
  void dispose() {
    _provider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_provider == null) {
      // In development, we must wait for initialization to avoid missing
      // starter icons that are now filesystem-only.
      // We return a transparent box or similar to avoid mounting children
      // that might depend on IconifyScope prematurely.
      return const SizedBox.shrink();
    }

    return IconifyScope(
      provider: _provider!,
      child: widget.child,
    );
  }
}
