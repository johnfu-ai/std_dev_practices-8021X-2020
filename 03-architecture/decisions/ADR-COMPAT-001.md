# ADR-COMPAT-001: Compile-Time Feature Gating Strategy

**GitHub Issue**: #33  
**Date**: 2026-05-10

See [GitHub Issue #33](https://github.com/johnfu-ai/std_dev_practices-8021X-2020/issues/33) for full context, alternatives, and consequences.

## Status

Accepted

## Context

IEEE 802.1X-2020 features must not affect existing wpa_supplicant users who do not opt in (StR-008, REQ-NF-COMPAT-001/002/003). Runtime configuration alone cannot guarantee zero impact on binary size, initialization paths, or existing state-machine behavior, and it leaves dormant code that can still regress. A gating mechanism is needed that removes 2020 code entirely from non-opt-in builds.

## Decision

Use layered compile-time gating: a master flag `CONFIG_IEEE8021X_2020` enables the overall feature set, with optional sub-flags (`CONFIG_IEEE8021X_2020_LOGON`, `CONFIG_IEEE8021X_2020_ANCP`) for granular components. When the flags are disabled, all 2020 code is excluded via `#ifdef`, yielding zero behavioral and binary-footprint impact.

## Consequences

- **Positive**: Clean opt-in; non-opt-in builds are behaviorally equivalent to baseline wpa_supplicant; sub-flags allow progressive adoption (e.g. MKA without Logon).
- **Negative**: Code paths gain `#ifdef` conditionals that can reduce readability; contributors must guard every new 2020 symbol.
- **Mitigation**: Guard macros are documented in `defconfig` and enforced by the build; CI compiles both with and without the master flag.

## Requirements Satisfied

- #4 (StR-008), #24 (REQ-NF-COMPAT-001), #25 (REQ-NF-COMPAT-002), #26 (REQ-NF-COMPAT-003)
