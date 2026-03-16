---
title: Performance Architecture
description: Deep dive into the optimizations that make the Iconify SDK the fastest icon solution for Flutter.
---

The Iconify SDK is designed from the ground up for high-performance rendering and minimal bundle footprint. This page explains the core architectural decisions that enable its speed.

## 1. The `.iconbin` Format

Traditional Iconify JSON collections can be several megabytes in size (e.g., MDI is ~3.3MB). Parsing these large JSON files at startup causes significant jank and latency.

The SDK introduces a proprietary **Binary Icon Format**, optimized for:
- **Zero Parsing**: Headers and indexes are read directly from memory via `ByteData`.
- **$O(\log n)$ Lookup**: Icons are indexed by name using a sorted string table, allowing the SDK to find and extract a single icon body in **under 5 microseconds**.
- **Lazy Decoding**: Only the requested icon's SVG body is decoded from the binary blob, keeping memory usage minimal.

## 2. Intelligent Caching

The SDK implements two distinct layers of caching:

### In-Memory Icon Cache
Stores raw `IconifyIconData` (SVG bodies and metadata). This avoids repeated lookups in the binary or JSON files.

### Picture Cache
Decouples icon data from the Flutter rendering lifecycle. When an SVG is parsed, the resulting `dart:ui.Picture` is stored in an LRU cache keyed by `(name, color, size)`. 
- **Benefit**: Re-rendering the same icon (even with different animations or parent rebuilds) has **zero parsing overhead**.
- **Memory Safety**: Automatically disposes of evicted `Picture` objects to prevent GPU memory leaks.

## 3. Parallel Preloading

Icon collections are often large and repetitive. The SDK utilizes Dart **Isolates** to move expensive I/O and decompression tasks off the main thread.

- **Background Decoding**: When preloading is enabled, the SDK spawns background isolates to decompress and index collections in parallel.
- **Main Thread Smoothness**: Even while loading 10,000+ icons, your app's UI remains responsive.

## 4. Bundle Intelligence

The SDK's CLI includes tools to aggressively reduce your app's download size:

- **Pruning**: Automatically detects icons used in your source code and removes everything else from your production bundle.
- **GZIP Compression**: All icon data assets are transparently compressed, typically yielding a **70% size reduction**.
- **Monochromatic Font Path**: For apps using only monochrome icons, the SDK can generate a highly optimized `.otf` font, which is **40% smaller** than raw SVG and leverages Flutter's native font rendering pipeline.

## Performance Benchmarks

| Operation | JSON (v1) | Binary (v2) | Improvement |
|---|---|---|---|
| **Startup Parse** | 29ms | 11ms | **2.6x** |
| **Icon Lookup** | 11.8ms | 3.9μs | **~3000x** |
| **Preloading (5 sets)**| 22ms | 7ms | **3.1x** |

*Benchmarks performed on an Apple M2 Workstation. For detailed methodology, see the [Performance Baseline](/reference/benchmarks).*
