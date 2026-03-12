import 'package:iconify_sdk_core/iconify_sdk_core.dart';

/// Generates optimized Dart code for Iconify icons.
class IconCodeGenerator {
  /// Generates the content of `icons.g.dart`.
  static String generate({
    required Set<String> usedIconNames,
    required Map<String, IconifyIconData> iconDataMap,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln(
        '// ignore_for_file: constant_identifier_names, library_private_types_in_public_api');
    buffer.writeln();
    buffer.writeln("import 'package:iconify_sdk_core/iconify_sdk_core.dart';");
    buffer.writeln();

    // Group icons by prefix for organization
    final groupedByPrefix = <String, List<String>>{};
    for (final fullName in usedIconNames) {
      final prefix = fullName.split(':').first;
      groupedByPrefix.putIfAbsent(prefix, () => []).add(fullName);
    }

    // 1. Generate namespace classes
    for (final prefix in groupedByPrefix.keys) {
      final className = 'Icons${_capitalize(prefix)}';
      buffer.writeln('/// Icon set: $prefix');
      buffer.writeln('class $className {');
      buffer.writeln('  $className._();');
      buffer.writeln();

      final icons = groupedByPrefix[prefix]!..sort();
      for (final fullName in icons) {
        final iconName = fullName.split(':').last;
        final data = iconDataMap[fullName];

        if (data != null) {
          final varName = _toCamelCase(iconName);
          buffer.writeln('  /// $fullName');
          buffer.writeln('  static const $varName = IconifyIconData(');
          buffer.writeln("    body: r'${data.body}',");
          buffer.writeln('    width: ${data.width},');
          buffer.writeln('    height: ${data.height},');
          buffer.writeln('  );');
          buffer.writeln();
        }
      }
      buffer.writeln('}');
      buffer.writeln();
    }

    // 2. Generate the initializer function
    buffer.writeln(
        '/// Injects all generated icons into a [MemoryIconifyProvider].');
    buffer.writeln('void initGeneratedIcons(MemoryIconifyProvider provider) {');
    for (final fullName in usedIconNames) {
      final prefix = fullName.split(':').first;
      final iconName = fullName.split(':').last;
      final className = 'Icons${_capitalize(prefix)}';
      final varName = _toCamelCase(iconName);

      if (iconDataMap.containsKey(fullName)) {
        buffer.writeln(
            "  provider.putIcon(const IconifyName('$prefix', '$iconName'), $className.$varName);");
      }
    }
    buffer.writeln('}');

    return buffer.toString();
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _toCamelCase(String s) {
    final parts = s.split(RegExp(r'[-_]'));
    if (parts.isEmpty) return s;

    final res = StringBuffer(parts[0]);
    for (var i = 1; i < parts.length; i++) {
      res.write(_capitalize(parts[i]));
    }
    return res.toString();
  }
}
