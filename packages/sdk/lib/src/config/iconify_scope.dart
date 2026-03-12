import 'package:flutter/widgets.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

/// Provides an [IconifyProvider] to the widget tree.
///
/// Use [IconifyScope.of] to retrieve the provider from descendant widgets.
class IconifyScope extends InheritedWidget {
  const IconifyScope({
    required this.provider,
    required super.child,
    super.key,
  });

  /// The provider used to resolve icons in this scope.
  final IconifyProvider provider;

  /// Retrieves the [IconifyProvider] from the nearest [IconifyScope].
  ///
  /// Throws a [FlutterError] if no [IconifyScope] is found in the [context].
  static IconifyProvider of(BuildContext context) {
    final IconifyProvider? result = maybeOf(context);
    if (result == null) {
      throw FlutterError(
        'IconifyScope.of() called with a context that does not contain an IconifyScope.\n'
        'Ensure that your widget tree is wrapped in an IconifyApp or IconifyScope.',
      );
    }
    return result;
  }

  /// Retrieves the [IconifyProvider] from the nearest [IconifyScope], or null.
  static IconifyProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<IconifyScope>()?.provider;
  }

  @override
  bool updateShouldNotify(IconifyScope oldWidget) {
    return provider != oldWidget.provider;
  }
}
