# ADR-003: Release Mode Remote Fetching Policy

## Status
Accepted

## Context
The Iconify Public API is a generous free service, but it is not intended to be used as a high-traffic production CDN. Relying on remote icon fetching in a published app introduces:
1. **Reliability Risks**: If the API is down or the user is offline, icons disappear.
2. **Performance Latency**: Network round-trips for small SVG assets are inefficient.
3. **Ethics/Sustainability**: Massive traffic from apps can strain the open-source infrastructure.

## Decision
By default, **remote fetching of icons will be blocked in Release builds.**

- The `RemoteIconifyProvider` will use a `DevModeGuard` to detect the build mode.
- In `Debug` and `Profile` modes, remote fetching is allowed to support rapid prototyping.
- In `Release` mode, only local sources (bundled assets, generated code, starter registry) will work.
- An explicit opt-in flag (`allowRemoteInRelease`) will be provided for edge cases, but its use will be discouraged.

## Consequences
- **Pros**:
    - Guaranteed offline reliability for users.
    - Zero network overhead for UI icons.
    - Responsible usage of the Iconify open-source API.
- **Cons**:
    - Minor friction: Developers *must* eventually bundle their icons before shipping (this is a feature, not a bug).
