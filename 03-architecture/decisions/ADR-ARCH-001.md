# ADR-ARCH-001: Extend wpa_supplicant In-Place

**GitHub Issue**: #32  
**Date**: 2026-05-10

See [GitHub Issue #32](https://github.com/johnfu-ai/std_dev_practices-8021X-2020/issues/32) for full context, alternatives, and consequences.

## Status

Accepted

## Context

IEEE 802.1X-2020 conformance requires substantial new functionality (Logon Process, MKA updates, NID management) on top of wpa_supplicant 2.11's existing 2010-era PAE/MKA base. The project must choose between (a) extending wpa_supplicant in-place within its source tree, (b) building a separate companion library, or (c) forking. A separate library or fork would duplicate the existing PAE/MKA/EAPOL code paths, complicate upstream synchronization, and force callers through a new integration boundary. Stakeholders require backward compatibility and minimal disruption to existing users (StR-008, REQ-NF-COMPAT-001).

## Decision

Extend wpa_supplicant in-place. Modify existing files under `src/pae/` and `src/eapol_supp/` and add new files (e.g. `ieee802_1x_logon.c/h`) within the existing source tree, rather than introducing a separate library or fork.

## Consequences

- **Positive**: No fork/library maintenance burden; new code reuses existing PAE/MKA/EAPOL infrastructure and follows established wpa_supplicant conventions; single integration path for callers.
- **Negative**: New code must respect wpa_supplicant's coding rules (C11, `os_*`/`wpa_printf` abstractions, no global state) and shares files where regressions can leak into existing behavior.
- **Mitigation**: All new behavior is compile-time gated (`CONFIG_IEEE8021X_2020` and sub-flags — see ADR-COMPAT-001), so users who do not opt in see zero behavioral change.

## Requirements Satisfied

- #1 (StR-001), #2 (StR-002), #3 (StR-003), #4 (StR-008)
- #24 (REQ-NF-COMPAT-001)
