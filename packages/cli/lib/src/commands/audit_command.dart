import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:iconify_sdk_builder/iconify_sdk_builder.dart';
import 'package:mason_logger/mason_logger.dart';

class AuditCommand extends Command<int> {
  AuditCommand({required Logger logger}) : _logger = logger;

  @override
  String get name => 'audit';

  @override
  String get description =>
      'Analyze icon bundle size and identify optimization opportunities.';

  final Logger _logger;

  @override
  Future<int> run() async {
    final configFile = File('iconify.yaml');
    if (!configFile.existsSync()) {
      _logger.err('iconify.yaml not found. Run "iconify init" first.');
      return ExitCode.config.code;
    }

    final IconifyBuildConfig config;
    try {
      config = IconifyBuildConfig.fromYaml(await configFile.readAsString());
    } catch (e) {
      _logger.err('Error parsing iconify.yaml: $e');
      return ExitCode.config.code;
    }

    final jsonFile = File('${config.dataDir}/used_icons.json');
    final gzFile = File('${config.dataDir}/used_icons.json.gz');

    File? activeFile;
    if (gzFile.existsSync()) {
      activeFile = gzFile;
    } else if (jsonFile.existsSync()) {
      activeFile = jsonFile;
    }

    if (activeFile == null) {
      _logger.err(
          'used_icons.json not found in ${config.dataDir}. Run "iconify generate" first.');
      return ExitCode.noInput.code;
    }

    final progress = _logger.progress('Analyzing ${activeFile.path}...');

    try {
      final bytes = await activeFile.readAsBytes();
      final Uint8List rawBytes;
      if (activeFile.path.endsWith('.gz')) {
        rawBytes = Uint8List.fromList(gzip.decode(bytes));
      } else {
        rawBytes = bytes;
      }

      final json = jsonDecode(utf8.decode(rawBytes)) as Map<String, dynamic>;
      final icons = json['icons'] as Map<String, dynamic>? ?? {};

      progress.complete('Audit complete.');
      _logger.info('');
      _logger.info(lightBlue.wrap('📦 Bundle Summary'));
      _logger.info('----------------------------------------');
      _logger.info('Total Icons:      ${icons.length}');
      _logger.info('Raw JSON Size:    ${_formatSize(rawBytes.length)}');

      if (activeFile.path.endsWith('.gz')) {
        _logger.info(
            'Compressed Size:  ${_formatSize(bytes.length)} (${((bytes.length / rawBytes.length) * 100).toStringAsFixed(1)}%)');
      } else {
        final gzipped = gzip.encode(rawBytes);
        _logger.info(
            'Potential GZIP:   ${_formatSize(gzipped.length)} (${((gzipped.length / rawBytes.length) * 100).toStringAsFixed(1)}%)');
      }

      // Analysis
      int monoCount = 0;
      int multiCount = 0;
      final heavyIcons = <String, int>{};

      icons.forEach((key, value) {
        final iconData = value as Map<String, dynamic>;
        final body = iconData['body'] as String? ?? '';
        final size = utf8.encode(jsonEncode(value)).length;

        if (body.contains('currentColor')) {
          monoCount++;
        } else {
          multiCount++;
        }

        if (size > 1024) {
          heavyIcons[key] = size;
        }
      });

      _logger.info('');
      _logger.info(lightBlue.wrap('🎨 Composition'));
      _logger.info('----------------------------------------');
      _logger.info('Monochrome:       $monoCount icons');
      _logger.info('Multi-color:      $multiCount icons');

      if (multiCount == 0 && monoCount > 0) {
        _logger.info(green.wrap(
            '💡 Optimization Tip: Your bundle is 100% monochrome. Use "--font" for native rendering.'));
      }

      if (heavyIcons.isNotEmpty) {
        _logger.info('');
        _logger.warn('⚠️  Heavy Icons (>1KB raw):');
        final sortedHeavy = heavyIcons.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        for (final entry in sortedHeavy.take(5)) {
          _logger.info(
              '   - ${entry.key.padRight(30)} ${_formatSize(entry.value)}');
        }
      }

      _logger.info('');
      _logger.info(lightBlue.wrap('🚀 Estimated Format Efficiency'));
      _logger.info('----------------------------------------');
      _logger.info('JSON (Raw):       ${_formatSize(rawBytes.length)}');
      _logger.info(
          'JSON (GZIP):      ${_formatSize(gzip.encode(rawBytes).length)}');

      // Rough estimates based on benchmarks
      final estBinary = (rawBytes.length * 0.88).toInt();
      final estBinaryGz = (rawBytes.length * 0.31).toInt();
      _logger.info('Binary (.iconbin): ${_formatSize(estBinary)} (est.)');
      _logger.info('Binary (GZIP):     ${_formatSize(estBinaryGz)} (est.)');

      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Audit failed: $e');
      return ExitCode.software.code;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    return '${(bytes / 1024).toStringAsFixed(2)} KB';
  }
}
