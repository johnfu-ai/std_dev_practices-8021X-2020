# ADR-MKA-001: Incremental MKA (KaY) Update to IEEE 802.1X-2020 Clause 9

**GitHub Issue**: #36  
**Date**: 2026-05-10

See [GitHub Issue #36](https://github.com/johnfu-ai/std_dev_practices-8021X-2020/issues/36) for full context, alternatives, and consequences.

## Status

Accepted

## Context

`src/pae/ieee802_1x_kay.c` implements the 2010 MKA (KaY) baseline. IEEE 802.1X-2020 Clause 9 adds features such as MKA suspension and group CAK distribution. A full rewrite risks regressing the mature, interoperable 2010 behavior and would destabilize consumers of the SecY interface. Stakeholders require backward compatibility and non-regression (StR-002, StR-008).

## Decision

Incrementally update `ieee802_1x_kay.c` in-place. Add 2020 features (suspension, group CAK) as compile-time-guarded functions alongside the existing code. Leave `ieee802_1x_kay_ctx` (the SecY interface) unchanged so existing consumers are unaffected.

## Consequences

- **Positive**: Preserves the proven 2010 code path and the stable `ieee802_1x_kay_ctx` API; 2020 features are opt-in and isolated; lower regression risk than a rewrite.
- **Negative**: The file carries a mix of 2010 and 2020 logic, which can complicate readability; some conditionals are unavoidable.
- **Mitigation**: 2020 paths are guarded by `CONFIG_IEEE8021X_2020` and covered by dedicated PAE unit tests.

## Requirements Satisfied

- #2 (StR-002), #13-#18 (REQ-F-MKA-001 through REQ-NF-MKA-001)
