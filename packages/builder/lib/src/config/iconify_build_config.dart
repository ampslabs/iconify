// ignore_for_file: prefer_const_constructors, document_ignores
import 'package:yaml/yaml.dart';

/// Configuration for the Iconify SDK build process.
///
/// This is typically parsed from an `iconify.yaml` file in the project root.
class IconifyBuildConfig {
  const IconifyBuildConfig({
    this.sets = const [],
    this.output = 'lib/icons.g.dart',
    this.dataDir = 'assets/iconify',
    this.mode = 'auto',
    this.licensePolicy = 'warn',
    this.customSets = const [],
    this.failOnMissing = false,
  });

  /// Parses configuration from a YAML string.
  factory IconifyBuildConfig.fromYaml(String yamlString) {
    if (yamlString.trim().isEmpty) {
      return const IconifyBuildConfig();
    }

    final doc = loadYaml(yamlString);
    if (doc is! YamlMap) {
      throw FormatException('Expected a YAML map at the root level.');
    }

    return IconifyBuildConfig(
      sets: _toStringList(doc['sets']),
      output: doc['output']?.toString() ?? 'lib/icons.g.dart',
      dataDir: doc['data_dir']?.toString() ?? 'assets/iconify',
      mode: doc['mode']?.toString() ?? 'auto',
      licensePolicy: doc['license_policy']?.toString() ?? 'warn',
      customSets: _toStringList(doc['custom_sets']),
      failOnMissing: doc['fail_on_missing'] == true,
    );
  }

  /// A list of icon identifiers or patterns to include (e.g., `mdi:home`, `lucide:*`).
  final List<String> sets;

  /// The path where the generated Dart file should be written.
  final String output;

  /// The directory where local JSON snapshots of icon sets are stored.
  final String dataDir;

  /// The operational mode: `auto`, `offline`, `generated`, `remoteAllowed`.
  final String mode;

  /// How to handle attribution-required licenses: `permissive`, `warn`, `strict`.
  final String licensePolicy;

  /// Paths to local JSON files for custom icon collections.
  final List<String> customSets;

  /// Whether the build should fail if an icon is not found.
  final bool failOnMissing;

  static List<String> _toStringList(dynamic node) {
    if (node == null) return [];
    if (node is YamlList) {
      return node.map((e) => e.toString()).toList();
    }
    if (node is List) {
      return node.map((e) => e.toString()).toList();
    }
    return [node.toString()];
  }
}
