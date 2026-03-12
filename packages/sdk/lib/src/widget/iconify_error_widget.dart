import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconify_sdk/iconify_sdk.dart' show IconifyIcon;
import 'package:iconify_sdk/src/widget/iconify_icon.dart' show IconifyIcon;
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

/// The default widget shown when an [IconifyIcon] fails to load.
///
/// In debug mode, this widget prints actionable hints to the console.
class IconifyErrorWidget extends StatelessWidget {
  const IconifyErrorWidget({
    required this.name,
    required this.error,
    super.key,
    this.size,
  });

  /// The name of the icon that failed to load.
  final IconifyName name;

  /// The exception that occurred.
  final IconifyException error;

  /// The intended size of the icon.
  final double? size;

  @override
  Widget build(BuildContext context) {
    _maybePrintDebugHint();

    return Tooltip(
      message: 'Iconify Error: ${error.message}',
      child: Container(
        width: size ?? 24,
        height: size ?? 24,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFEF9A9A)),
        ),
        child: Center(
          child: Icon(
            Icons.error_outline,
            color: const Color(0xFFD32F2F),
            size: (size ?? 24) * 0.6,
          ),
        ),
      ),
    );
  }

  void _maybePrintDebugHint() {
    if (!kDebugMode) return;

    if (error is IconNotFoundException) {
      debugPrint('Iconify SDK [HINT]: Icon "$name" not found.');
      debugPrint(
          'Try running: dart run iconify_sdk_cli sync --collections ${name.prefix}');
    } else if (error is CollectionNotFoundException) {
      debugPrint('Iconify SDK [HINT]: Collection "${name.prefix}" is missing.');
      debugPrint(
          'Try running: dart run iconify_sdk_cli sync --collections ${name.prefix}');
    } else {
      debugPrint('Iconify SDK [ERROR]: $error');
    }
  }
}
