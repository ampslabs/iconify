import 'dart:io';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

void main() async {
  final jsonPath = '../../examples/basic/assets/iconify/mdi.json';
  final file = File(jsonPath);
  if (!file.existsSync()) {
    // Benchmarks are expected to print to console.
    // ignore: avoid_print
    print(
        'Error: mdi.json not found at $jsonPath. Run sync in examples/basic first.');
    return;
  }

  final jsonString = await file.readAsString();
  // Benchmarks are expected to print to console.
  // ignore: avoid_print
  print(
      'Collection size: ${(jsonString.length / 1024 / 1024).toStringAsFixed(2)} MB');

  // Benchmark JSON Parsing
  final swJson = Stopwatch()..start();
  final collection = IconifyJsonParser.parseCollectionString(jsonString);
  swJson.stop();
  // Benchmarks are expected to print to console.
  // ignore: avoid_print
  print(
      'JSON Parse Time: ${swJson.elapsedMilliseconds}ms (${collection.iconCount} icons)');

  // Benchmark Binary Encoding
  final swEncode = Stopwatch()..start();
  final encoded = BinaryIconFormat.encode(collection);
  swEncode.stop();
  // Benchmarks are expected to print to console.
  // ignore: avoid_print
  print('Binary Encode Time: ${swEncode.elapsedMilliseconds}ms');
  // Benchmarks are expected to print to console.
  // ignore: avoid_print
  print(
      'Binary Size: ${(encoded.length / 1024 / 1024).toStringAsFixed(2)} MB (${(encoded.length / jsonString.length * 100).toStringAsFixed(1)}% of JSON)');

  // Benchmark Binary Decoding (Full)
  final swDecode = Stopwatch()..start();
  BinaryIconFormat.decode(encoded);
  swDecode.stop();
  // Benchmarks are expected to print to console.
  // ignore: avoid_print
  print('Binary Decode (Full) Time: ${swDecode.elapsedMilliseconds}ms');

  // Benchmark Binary Decode (Single Icon - Average of 1000 lookups)
  final iconNames = collection.icons.keys.toList();
  final swLookup = Stopwatch()..start();
  for (var i = 0; i < 1000; i++) {
    final name = iconNames[i % iconNames.length];
    BinaryIconFormat.decodeIcon(encoded, name);
  }
  swLookup.stop();
  // Benchmarks are expected to print to console.
  // ignore: avoid_print
  print(
      'Binary Single Icon Lookup (avg): ${(swLookup.elapsedMicroseconds / 1000).toStringAsFixed(3)}μs');

  // Comparison
  // Benchmarks are expected to print to console.
  // ignore: avoid_print
  print('\n--- SUMMARY ---');
  // Benchmarks are expected to print to console.
  // ignore: avoid_print
  print(
      'Full Parse Speedup: ${(swJson.elapsedMilliseconds / swDecode.elapsedMilliseconds).toStringAsFixed(1)}x');

  // Clean up
  final binFile = File('mdi.iconbin');
  await binFile.writeAsBytes(encoded);
  // Benchmarks are expected to print to console.
  // ignore: avoid_print
  print('Wrote mdi.iconbin for reference.');
}
