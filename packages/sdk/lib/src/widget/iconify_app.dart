import 'package:flutter/cupertino.dart' show CupertinoApp;
import 'package:flutter/material.dart' show MaterialApp;
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

    // 2. Build the provider chain based on config
    if (mounted) {
      setState(() {
        _provider = buildProviderChain(widget.config);
      });
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
