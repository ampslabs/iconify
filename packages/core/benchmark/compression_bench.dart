import 'dart:convert';
import 'dart:io';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

void main() async {
  final jsonPath = '../../examples/basic/assets/iconify/mdi.json';
  final file = File(jsonPath);
  if (!file.existsSync()) {
    // Benchmarks print results to stdout for documentation.
    // ignore: avoid_print
    print('Error: mdi.json not found. Run sync in examples/basic first.');
    return;
  }

  final jsonString = await file.readAsString();
  final originalCollection =
      IconifyJsonParser.parseCollectionString(jsonString);

  // Create a 50-icon subset
  final subsetIcons =
      Map.fromEntries(originalCollection.icons.entries.take(50));

  final subsetCollection = ParsedCollection(
    prefix: originalCollection.prefix,
    info: originalCollection.info,
    icons: subsetIcons,
    aliases: {},
    defaultWidth: originalCollection.defaultWidth,
    defaultHeight: originalCollection.defaultHeight,
  );

  // 1. JSON Compression
  final subsetJson = {
    'prefix': subsetCollection.prefix,
    'icons': subsetCollection.icons
        .map((key, value) => MapEntry(key, value.toJson())),
  };
  final subsetJsonStr = jsonEncode(subsetJson);
  final subsetJsonBytes = utf8.encode(subsetJsonStr);
  final compressedJson = gzip.encode(subsetJsonBytes);

  // 2. Binary Compression
  final encodedBinary = BinaryIconFormat.encode(subsetCollection);
  final compressedBinary = gzip.encode(encodedBinary);

  // Results
  // Benchmarks are expected to print to console.
  // ignore: avoid_print
  print('--- Compression Benchmark (50 MDI Icons) ---');
  // Benchmarks are expected to print to console.
  // ignore: avoid_print
  print('Format | Raw Size | Compressed Size | Reduction');
  // Benchmarks are expected to print to console.
  // ignore: avoid_print
  print('-------|----------|-----------------|-----------');
  _printRow('JSON', subsetJsonBytes.length, compressedJson.length);
  _printRow('Binary', encodedBinary.length, compressedBinary.length);
}

void _printRow(String label, int raw, int compressed) {
  final reduction = (1 - (compressed / raw)) * 100;
  // Benchmarks are expected to print to console.
  // ignore: avoid_print
  print(
      '${label.padRight(6)} | ${(raw / 1024).toStringAsFixed(2).padLeft(6)} KB | ${(compressed / 1024).toStringAsFixed(2).padLeft(13)} KB | ${reduction.toStringAsFixed(1)}%');
}
