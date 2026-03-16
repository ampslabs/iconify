import 'dart:js_interop';
import 'dart:typed_data';

@JS('Response')
extension type Response._(JSObject _) implements JSObject {
  external Response(JSAny body);
  external JSObject get body;
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

@JS('DecompressionStream')
extension type DecompressionStream._(JSObject _) implements JSObject {
  external DecompressionStream(JSString format);
}

extension ReadableStreamExtension on JSObject {
  @JS('pipeThrough')
  external JSObject pipeThrough(JSObject transform);
}

/// Web implementation of GZIP decompression using Compression Streams API.
Future<Uint8List> decompressGZip(Uint8List bytes) async {
  final ds = DecompressionStream('gzip'.toJS);

  // 1. Create a Response with the compressed bytes
  final response = Response(bytes.toJS);

  // 2. Pipe the response body through the decompression stream
  final decompressedStream = response.body.pipeThrough(ds);

  // 3. Create a new Response from the decompressed stream to easily get an ArrayBuffer
  final decompressedResponse = Response(decompressedStream);

  final buffer = await decompressedResponse.arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}
