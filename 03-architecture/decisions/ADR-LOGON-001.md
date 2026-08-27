# ADR-LOGON-001: Logon Process as New State Machine Module in src/pae/

**GitHub Issue**: #37  
**Date**: 2026-05-10

See [GitHub Issue #37](https://github.com/johnfu-ai/std_dev_practices-8021X-2020/issues/37) for full context, alternatives, and consequences.

## Status

Accepted

## Context

The Logon Process (IEEE 802.1X-2020 Clause 12) is a new NID-aware access function with no direct counterpart in the 2010 base. It must coordinate with the Supplicant PACP, KaY, and Controlled Port state machines. Folding it into an existing state machine would violate single-responsibility and complicate testing; placing it outside `src/pae/` would break the established PAE module layout.

## Decision

Implement the Logon Process as a first-class state machine in `src/pae/ieee802_1x_logon.c/h`, with an `ieee802_1x_logon_ctx` function-pointer struct for dependency injection. Add a bridge file `wpa_supplicant/wpas_logon.c` that mirrors the `wpas_kay.c` pattern to wire concrete implementations. Gate the module with `CONFIG_IEEE8021X_2020_LOGON`.

## Consequences

- **Positive**: Clear separation of concerns; testable in isolation via mock injection through `ieee802_1x_logon_ctx`; consistent with the existing KaY module pattern; independently disableable.
- **Negative**: A new module to maintain and integrate with PACP/KaY/CP; bridge-file boilerplate.
- **Mitigation**: The DI context and bridge pattern are reused from KaY, so the integration contract is already proven.

## Requirements Satisfied

- #3 (StR-003), #19-#23 (REQ-F-LOGON-001 through REQ-NF-LOGON-001)
