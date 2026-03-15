# Performance Baseline

This document tracks performance benchmarks for the Iconify SDK v2.

## Test Environment
- **Device**: Linux Workstation
- **Dart Version**: 3.5.0
- **Data Set**: Material Design Icons (MDI) full collection (~7,600 icons, 3.3 MB JSON)

## Parse Performance (Cold Start)

| Format | Full Collection Parse | Single Icon Lookup | Size on Disk |
|---|---|---|---|
| **JSON** | 73ms | ~2ms (est) | 3.32 MB |
| **Binary (.iconbin)** | 24ms | 0.005ms (4.8μs) | 2.91 MB |
| **Improvement** | **3.0x** | **~400x** | **12% smaller** |

### Insights
- **Binary Format**: The binary format eliminates JSON tokenization and string escaping overhead. The string table with offset index allows $O(1)$ access to any string.
- **Lazy Decoding**: `BinaryIconifyProvider` uses `decodeIcon` to extract single icons without parsing the rest of the collection, leading to sub-millisecond resolution even for massive sets.
- **Zero Parsing**: Header and index structures are designed for direct `ByteData` reading, making the "parse" time almost entirely limited by memory I/O.

## Benchmarks Log

### 2026-03-15
- Initial benchmark of `BinaryIconFormat` v1.
- Results confirmed 3x faster full parse and extremely fast random access.
