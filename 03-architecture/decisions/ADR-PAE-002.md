# ADR-PAE-002: Function-Pointer Dependency Injection for Inter-SM Interfaces

**GitHub Issue**: #35  
**Date**: 2026-05-10

See [GitHub Issue #35](https://github.com/johnfu-ai/std_dev_practices-8021X-2020/issues/35) for full context, alternatives, and consequences.

## Status

Accepted

## Context

New inter-state-machine interfaces (Logon↔PACP, Logon↔KaY, Logon↔CP) must be testable in isolation and decoupled from concrete wpa_supplicant internals. Direct calls to global/singleton objects would create hidden couplings, block mock-based unit testing (REQ-NF-TEST-001), and violate the project's "no global protocol state" constraint.

## Decision

Use function-pointer context structs for all new inter-SM interfaces, following the established `ieee802_1x_kay_ctx` pattern. Define `ieee802_1x_logon_ctx` and `ieee802_1x_pacp_logon_if` as function-pointer tables passed by pointer. Bridge files (e.g. `wpas_logon.c`) wire the concrete implementations, mirroring `wpas_kay.c`.

## Consequences

- **Positive**: Highly testable — unit tests inject mock function tables; consistent with the proven KaY pattern; no hidden global state; clear ownership of each interface.
- **Negative**: Boilerplate for bridge files and context structs; slight indirection cost at call sites.
- **Mitigation**: The pattern is already established and understood by maintainers, so adoption cost is low.

## Requirements Satisfied

- #6 (REQ-F-PAE-002), #11 (REQ-NF-TEST-001), #19 (REQ-F-LOGON-001), #21 (REQ-F-LOGON-003), #23 (REQ-NF-LOGON-001)
