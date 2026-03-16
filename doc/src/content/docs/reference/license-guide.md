---
title: License Guide
description: A guide to Iconify collection licenses, classifying collections by their licensing requirements to help configure your license_policy.
---

This page classifies Iconify collections based on their licensing requirements. Use this guide to configure your `license_policy` in `iconify.yaml`.

## Safe Collections (No Attribution Required)

These collections use extremely permissive licenses (MIT, Apache 2.0, ISC). They are safe to bundle in commercial and private applications without explicit attribution in the UI.

| Prefix | Name | License (SPDX) |
|---|---|---|
| `mdi` | Material Design Icons | Apache-2.0 |
| `lucide` | Lucide | ISC |
| `tabler` | Tabler Icons | MIT |
| `heroicons` | Heroicons | MIT |
| `ri` | Remix Icon | Apache-2.0 |
| `carbon` | Carbon Icons | Apache-2.0 |
| `bi` | Bootstrap Icons | MIT |
| `ph` | Phosphor Icons | MIT |
| `fluent` | Fluent System Icons | MIT |

## Attribution Required

These collections (often CC BY 4.0) allow commercial use but **require attribution** to the author. If using these, we recommend displaying author credits in your "About" or "Legal" screen.

| Prefix | Name | License (SPDX) |
|---|---|---|
| `fa6-free` | Font Awesome 6 Free | CC-BY-4.0 |
| `la` | Line Awesome | CC-BY-4.0 |
| `icomoon-free` | IcoMoon Free | CC-BY-4.0 |
| `entypo` | Entypo+ | CC-BY-SA-4.0 |

## High Risk / Do Not Bundle

These collections have restrictive terms (GPL, Non-Commercial) that may conflict with standard App Store policies or commercial project requirements. Use with extreme caution.

| Prefix | Name | License / Note |
|---|---|---|
| (various) | GPL Licenses | Copyleft requirements may apply. |
| (various) | Non-Commercial | Not allowed in revenue-generating apps. |

:::tip
This list is a helper, not legal advice. Always verify the `license` field in the icon set's metadata for the most accurate information.
:::
