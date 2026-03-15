/// Scans Dart source code for Iconify icon identifiers using a hybrid approach.
///
/// It uses robust regular expressions to find IconifyIcon and IconifyName
/// patterns in the source text. This approach is more resilient to
/// analyzer version changes while maintaining high precision.
class IconNameScanner {
  final Set<String> iconNames = {};

  /// Patterns for Iconify usage
  static final _literalPattern = RegExp(
    r"IconifyIcon\(\s*['"
    r'"]'
    r'([a-z0-9][a-z0-9\-]*:[a-z0-9][a-z0-9\-]*)'
    r"['"
    r'"]'
    r'[\s\S]*?\)',
    caseSensitive: false,
  );

  static final _namePattern = RegExp(
    r"IconifyName\(\s*['"
    r'"]'
    r'([a-z0-9][a-z0-9\-]*)'
    r"['"
    r'"]'
    r"\s*,\s*['"
    r'"]'
    r'([a-z0-9][a-z0-9\-]*)'
    r"['"
    r'"]'
    r'[\s\S]*?\)',
    caseSensitive: false,
  );

  /// Scans the provided [content] for icon names.
  void scan(String content) {
    // 1. Find simple string patterns: IconifyIcon('mdi:home')
    for (final match in _literalPattern.allMatches(content)) {
      final id = match.group(1);
      if (id != null) iconNames.add(id);
    }

    // 2. Find IconifyName patterns: IconifyName('mdi', 'home')
    for (final match in _namePattern.allMatches(content)) {
      final prefix = match.group(1);
      final name = match.group(2);
      if (prefix != null && name != null) {
        iconNames.add('$prefix:$name');
      }
    }
  }
}
