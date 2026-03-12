# Safe Icon Collections

This guide lists popular Iconify collections that use permissive licenses (MIT, Apache 2.0, ISC). These collections are **safe for commercial use** and generally **do not require attribution** in your application's user interface.

## Recommended Permissive Collections

The following sets are highly recommended for any project:

| Collection | Prefix | License |
|---|---|---|
| **Material Design Icons** | `mdi` | Apache 2.0 |
| **Lucide** | `lucide` | ISC |
| **Tabler Icons** | `tabler` | MIT |
| **Heroicons** | `heroicons` | MIT |
| **Phosphor Icons** | `ph` | MIT |
| **Bootstrap Icons** | `bi` | MIT |
| **Feather** | `feather` | MIT |
| **Remix Icon** | `ri` | Apache 2.0 |
| **Radix Icons** | `radix-icons` | MIT |

## Attribution Required Collections

Some popular collections use licenses like **CC BY 4.0**, which requires you to provide credit to the author somewhere in your app (e.g., an "About" or "Legal" screen).

- **Font Awesome (Free)** (`fa-solid`, `fa-regular`)
- **Ionicons** (`ion`)
- **Line Awesome** (`la`)

## Restrictive Licenses

We recommend avoiding collections with **GPL** or **Non-Commercial (NC)** licenses in commercial products, as they can impose legal restrictions on your source code or business model.

---

**Tip**: Use the `dart run iconify_sdk_cli:iconify licenses` command to generate a full report of all icon sets used in your specific application.
