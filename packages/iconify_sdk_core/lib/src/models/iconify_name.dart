import 'package:meta/meta.dart';
import '../errors/iconify_exception.dart';

/// An immutable, validated Iconify icon identifier.
///
/// Every icon in the Iconify ecosystem is identified by a two-part name:
/// `prefix:iconName`, where `prefix` is the icon set (e.g., `mdi`, `lucide`)
/// and `iconName` is the specific icon (e.g., `home`, `settings`).
///
/// ```dart
/// final name = IconifyName.parse('mdi:home');
/// print(name.prefix);    // mdi
/// print(name.iconName);  // home
/// print(name);           // mdi:home
///
/// // Const construction when values are known:
/// const name = IconifyName('mdi', 'home');
/// ```
@immutable
final class IconifyName {

  /// Parses a canonical `prefix:name` string into an [IconifyName].
  ///
  /// Throws [InvalidIconNameException] if the input is not valid.
  ///
  /// ```dart
  /// final name = IconifyName.parse('mdi:home');      // OK
  /// IconifyName.parse('mdi-home');                    // throws: wrong separator
  /// IconifyName.parse(':home');                       // throws: empty prefix
  /// IconifyName.parse('MDI:Home');                    // throws: uppercase not allowed
  /// ```
  factory IconifyName.parse(String value) {
    final colonIndex = value.indexOf(':');

    if (colonIndex == -1) {
      throw InvalidIconNameException(
        input: value,
        message: 'Expected format \'prefix:name\', got \'$value\'. '
            'Did you mean to use a colon instead of a hyphen or slash?',
      );
    }

    if (value.indexOf(':', colonIndex + 1) != -1) {
      throw InvalidIconNameException(
        input: value,
        message: 'Expected exactly one colon in \'$value\', found multiple. '
            'Format must be \'prefix:name\'.',
      );
    }

    final prefix = value.substring(0, colonIndex);
    final name = value.substring(colonIndex + 1);

    _validatePart(value, prefix, 'prefix');
    _validatePart(value, name, 'name');

    return IconifyName(prefix, name);
  }
  /// Creates an [IconifyName] from pre-validated parts.
  ///
  /// Prefer [IconifyName.parse] when working with user input or API data.
  /// This constructor does NOT validate inputs for performance — use only
  /// when inputs are already known-good (e.g., from generated code).
  const IconifyName(this.prefix, this.iconName);

  /// The icon set prefix, e.g., `mdi`, `lucide`, `tabler`.
  final String prefix;

  /// The icon name within the set, e.g., `home`, `settings`, `arrow-left`.
  final String iconName;

  static final _prefixPattern =
      RegExp(r'^[a-z0-9][a-z0-9\-]*[a-z0-9]$|^[a-z0-9]$');
  static final _namePattern =
      RegExp(r'^[a-z0-9][a-z0-9\-]*[a-z0-9]$|^[a-z0-9]$');
  static const _maxPartLength = 64;

  /// Tries to parse a string, returning `null` on failure instead of throwing.
  ///
  /// ```dart
  /// final name = IconifyName.tryParse('mdi:home');   // IconifyName
  /// final bad  = IconifyName.tryParse('mdi-home');   // null
  /// ```
  static IconifyName? tryParse(String value) {
    try {
      return IconifyName.parse(value);
    } on InvalidIconNameException {
      return null;
    }
  }

  static void _validatePart(String input, String part, String partName) {
    if (part.isEmpty) {
      throw InvalidIconNameException(
        input: input,
        message:
            'The $partName part of \'$input\' is empty. Both prefix and name are required.',
      );
    }
    if (part.length > _maxPartLength) {
      throw InvalidIconNameException(
        input: input,
        message: 'The $partName part of \'$input\' is ${part.length} characters, '
            'exceeding the maximum of $_maxPartLength.',
      );
    }
    if (partName == 'prefix' && !_prefixPattern.hasMatch(part)) {
      throw InvalidIconNameException(
        input: input,
        message: 'The prefix \'$part\' in \'$input\' contains invalid characters. '
            'Prefixes must use only lowercase letters (a-z), digits (0-9), '
            'and hyphens (-), and must not start or end with a hyphen.',
      );
    }
    if (partName == 'name' && !_namePattern.hasMatch(part)) {
      throw InvalidIconNameException(
        input: input,
        message:
            'The icon name \'$part\' in \'$input\' contains invalid characters. '
            'Names must use only lowercase letters (a-z), digits (0-9), '
            'and hyphens (-), and must not start or end with a hyphen.',
      );
    }
  }

  /// Returns the canonical string representation: `prefix:iconName`.
  @override
  String toString() => '$prefix:$iconName';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconifyName &&
          runtimeType == other.runtimeType &&
          prefix == other.prefix &&
          iconName == other.iconName;

  @override
  int get hashCode => Object.hash(prefix, iconName);
}
