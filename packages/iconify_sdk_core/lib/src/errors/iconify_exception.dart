import '../models/iconify_name.dart';

/// Base sealed exception for all Iconify errors.
///
/// Use pattern matching to handle specific error types:
/// ```dart
/// try {
///   await provider.getIcon(name);
/// } on IconifyException catch (e) {
///   switch (e) {
///     case InvalidIconNameException(:final input):
///       print('Bad name: $input');
///     case IconNotFoundException(:final name):
///       print('Not found: $name');
///     // ...
///   }
/// }
/// ```
sealed class IconifyException implements Exception {
  const IconifyException({required this.message});

  /// Human-readable description. Always actionable. Never "an error occurred."
  final String message;

  @override
  String toString() => 'IconifyException($runtimeType): $message';
}

/// Thrown when an icon identifier string cannot be parsed.
///
/// Happens when the input does not match `prefix:name` format.
final class InvalidIconNameException extends IconifyException {
  const InvalidIconNameException({
    required this.input,
    required super.message,
  });

  /// The original string that failed to parse.
  final String input;
}

/// Thrown when an icon is not found in any provider.
final class IconNotFoundException extends IconifyException {
  const IconNotFoundException({
    required this.name,
    required super.message,
    this.suggestion,
  });

  /// The [IconifyName] that was requested but not found.
  final IconifyName name;

  /// Optional did-you-mean suggestion (e.g., 'lucide:settings' for 'lucide:setting').
  final String? suggestion;
}

/// Thrown when a collection is not available in any configured provider.
final class CollectionNotFoundException extends IconifyException {
  const CollectionNotFoundException({
    required this.prefix,
    required super.message,
    this.wasRemoteAttempted = false,
  });

  final String prefix;

  /// Whether a remote fetch was attempted before this exception was thrown.
  final bool wasRemoteAttempted;
}

/// Thrown on HTTP or network-layer failures.
final class IconifyNetworkException extends IconifyException {
  const IconifyNetworkException({
    required super.message,
    this.statusCode,
    this.uri,
  });

  final int? statusCode;
  final Uri? uri;
}

/// Thrown when license metadata is required but missing.
final class IconifyLicenseException extends IconifyException {
  const IconifyLicenseException({
    required this.prefix,
    required super.message,
  });

  final String prefix;
}

/// Thrown when the Iconify JSON data is malformed or fails schema validation.
final class IconifyParseException extends IconifyException {
  const IconifyParseException({
    required super.message,
    this.field,
    this.rawValue,
  });

  /// The JSON field that caused the parse failure, if known.
  final String? field;

  /// The raw value that could not be parsed, if present.
  final Object? rawValue;
}

/// Thrown when a circular alias chain is detected.
final class CircularAliasException extends IconifyException {
  const CircularAliasException({
    required this.chain,
    required super.message,
  });

  /// The full alias chain that created the cycle.
  /// Example: ['home-alias', 'home-alias2', 'home-alias']
  final List<String> chain;
}

/// Thrown when the local cache fails to read or write.
final class IconifyCacheException extends IconifyException {
  const IconifyCacheException({
    required super.message,
    this.cause,
  });

  final Object? cause;
}
