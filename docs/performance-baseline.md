# Performance Baseline

This document tracks performance benchmarks for the Iconify SDK v2.

## Test Environment
- **Device**: macOS Workstation (Apple M2)
- **Dart Version**: 3.5.0
- **Data Set**: Material Design Icons (MDI) full collection (~7,600 icons, 3.3 MB JSON)

## Parse Performance (Cold Start)

| Format | Full Collection Parse | Single Icon Lookup | Size on Disk |
|---|---|---|---|
| **JSON** | 29ms | 11.8ms | 3.32 MB |
| **Binary (.iconbin)** | 11ms | 0.004ms (3.9μs) | 2.91 MB |
| **Improvement** | **2.6x** | **~3000x** | **12% smaller** |

### Insights
- **Binary Format**: The binary format eliminates JSON tokenization and string escaping overhead. The string table with offset index allows $O(1)$ access to any string.
- **Lazy Decoding**: `BinaryIconifyProvider` uses `decodeIcon` to extract single icons without parsing the rest of the collection, leading to sub-millisecond resolution even for massive sets.
- **Zero Parsing**: Header and index structures are designed for direct `ByteData` reading, making the "parse" time almost entirely limited by memory I/O.

## Runtime Rendering Performance

| Component | Operation | Time (μs) |
|---|---|---|
| **PictureCache** | Cache Hit | 0.4 |
| **AliasResolver** | Depth-5 Chain | 0.5 |
| **IconifyName** | String Parse | 0.1 |

## Bundle Size Optimization (Phase D)

Targeting ≤ 15KB for a real-world app with 50 icons.

### GZIP Compression (50 MDI Icons)

| Format | Raw Size | GZIP Size | Reduction |
|---|---|---|---|
| **JSON** | 21.5 KB | 5.5 KB | **74%** |
| **Binary (.iconbin)** | 21.3 KB | 6.7 KB | **68%** |

*Note: JSON compresses slightly better because GZIP thrives on the repetitive structure of text-based JSON, but Binary still offers significant savings and much faster lookup speeds.*

### Icon Font Optimization (Monochrome)

Comparison for 500 monochrome icons (MDI):

| Format | Size (Raw) | Size (GZIP) |
|---|---|---|
| **SVG (JSON)** | 168.7 KB | 38.1 KB |
| **Icon Font (OTF)** | 93.7 KB | 43.6 KB |

*Note: While Icon Font is 44% smaller than raw SVG, GZIP compression is extremely effective on SVG's repetitive text structure, making GZIP-SVG the absolute smallest for many common scenarios. The Font path remains a high-performance alternative for environments where GZIP is not available or for legacy reasons.*

## Benchmarks Log

### 2026-03-16
- Initial Phase C & D benchmarks.
- Confirmed binary lookup speedup and GZIP compression ratios.
- Verified parallel preloading 3.1x improvement.
