# Iconify Binary Format Spec (v1)

The `.iconbin` format is an optimized binary representation of an Iconify icon collection. It is designed for fast random access, minimal memory footprint, and zero-parsing startup.

## Structure

| Section | Description |
|---|---|
| **Header** | Magic bytes, version, and offsets to other sections. |
| **Metadata** | Collection-level information (prefix, name, license, defaults). |
| **Icon Index** | Sorted list of icon names and pointers to their records. |
| **Alias Index** | Sorted list of alias names and pointers to their records. |
| **Icon Records** | Fixed-size records for each icon. |
| **Alias Records** | Fixed-size records for each alias. |
| **String Table** | Index of string offsets followed by raw UTF-8 data. |

---

## Header (28 bytes)

| Offset | Type | Description |
|---|---|---|
| 0 | uint32 | Magic Bytes: `0x49 0x43 0x4F 0x4E` ("ICON") |
| 4 | uint8 | Version: `0x01` |
| 5 | uint8 | Reserved: `0x00` |
| 6 | uint16 | Icon Count |
| 8 | uint16 | Alias Count |
| 10 | uint32 | String Count |
| 14 | uint32 | Metadata Offset |
| 18 | uint32 | Icon Index Offset |
| 22 | uint32 | Alias Index Offset |
| 26 | uint32 | String Table Offset |

---

## Metadata

| Field | Type | Description |
|---|---|---|
| Prefix | uint32 | String index for the collection prefix (e.g., "mdi"). |
| Name | uint32 | String index for the human-readable name. |
| Total Icons | uint32 | Total icons in the upstream set. |
| Author Name | uint32 | String index. |
| Author URL | uint32 | String index. |
| License Title | uint32 | String index. |
| License SPDX | uint32 | String index. |
| License URL | uint32 | String index. |
| Attribution | uint8 | `0x01` if requires attribution, else `0x00`. |
| Default Width | float32 | Default viewbox width. |
| Default Height | float32 | Default viewbox height. |

---

## Index Sections (Icon & Alias)

The index allows binary search for icon/alias names.

| Field | Type | Description |
|---|---|---|
| Name Index | uint32 | String index for the icon/alias name. |
| Record Offset | uint32 | Absolute offset to the corresponding Record section. |

---

## Icon Record (14 bytes)

| Field | Type | Description |
|---|---|---|
| Body | uint32 | String index for the SVG path data. |
| Width | float32 | Viewbox width. |
| Height | float32 | Viewbox height. |
| Flags | uint8 | Bit 0: hidden, Bit 1: hFlip, Bit 2: vFlip. |
| Rotate | uint8 | 0, 1 (90°), 2 (180°), 3 (270°). |

---

## Alias Record (14 bytes)

| Field | Type | Description |
|---|---|---|
| Parent | uint32 | String index for the parent icon name. |
| Width | float32 | Width override (optional). |
| Height | float32 | Height override (optional). |
| Flags | uint8 | See below. |
| Rotate | uint8 | 0, 1, 2, 3. |

**Alias Flags:**
- Bit 0: hasWidth override
- Bit 1: hasHeight override
- Bit 2: hasRotate override
- Bit 3: hasHFlip override
- Bit 4: hasVFlip override
- Bit 5: hFlip value
- Bit 6: vFlip value

---

## String Table

Strings are indexed by their order of appearance (0-based).

| Field | Type | Description |
|---|---|---|
| Offsets | uint32[String Count] | Absolute offsets to the start of each length-prefixed string. |
| Strings | LengthPrefixedString[] | `uint32 length` + `uint8 data[]` |
