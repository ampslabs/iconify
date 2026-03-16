---
title: Performance Baseline
description: Detailed performance metrics and benchmarks for the Iconify SDK v2.
---

This document tracks performance benchmarks for the Iconify SDK v2 across different platforms and formats.

## Test Environment
- **Device**: macOS Workstation (Apple M2)
- **Dart Version**: 3.5.0
- **Data Set**: Material Design Icons (MDI) full collection (~7,600 icons, 3.3 MB JSON)

## Parse Performance (Cold Start)

| Format | Full Collection Parse | Single Icon Lookup | Size on Disk |
|---|---|---|---|
| **JSON** | 29ms | 11.8ms | 3.32 MB |
| **Binary (.iconbin)** | 11ms | 3.9μs | 2.91 MB |
| **Improvement** | **2.6x** | **~3000x** | **12% smaller** |

## Runtime Performance

| Component | Operation | Time (μs) |
|---|---|---|
| **PictureCache** | Cache Hit | 0.4 |
| **AliasResolver** | Depth-5 Chain | 0.5 |
| **IconifyName** | String Parse | 0.1 |

## Bundle Size Optimization

Targeting ≤ 15KB for a real-world app with 50 icons.

### GZIP Compression (50 MDI Icons)

| Format | Raw Size | GZIP Size | Reduction |
|---|---|---|---|
| **JSON** | 21.5 KB | 5.5 KB | **74%** |
| **Binary (.iconbin)** | 21.3 KB | 6.7 KB | **68%** |

### Icon Font Optimization (Monochrome)

Comparison for 500 monochrome icons (MDI):

| Format | Size (Raw) | Size (GZIP) |
|---|---|---|
| **SVG (JSON)** | 168.7 KB | 38.1 KB |
| **Icon Font (OTF)** | 93.7 KB | 43.6 KB |

## Methodology

### Parse Benchmarks
Measured using `Stopwatch` on a release-mode Dart VM. "Full Parse" includes reading the file from disk and decoding the entire structure. "Single Icon Lookup" for JSON includes `jsonDecode` + `extractIcon`, whereas for Binary it uses `decodeIcon` directly on the byte buffer.

### PictureCache Benchmarks
Measured using `testWidgets` in a Flutter environment. "Cache Hit" measures the time to retrieve an existing `dart:ui.Picture` from the LRU cache.

### Size Benchmarks
Raw sizes are the byte counts of the generated files. GZIP sizes are measured after applying `gzip.encode` with default settings.
