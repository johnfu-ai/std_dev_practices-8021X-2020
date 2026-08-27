# ADR-PAE-001: Incremental Supplicant PACP State Machine Update

**GitHub Issue**: #34  
**Date**: 2026-05-10

See [GitHub Issue #34](https://github.com/johnfu-ai/std_dev_practices-8021X-2020/issues/34) for full context, alternatives, and consequences.

## Status

Accepted

## Context

`src/eapol_supp/eapol_supp_sm.c` implements the 802.1X-2004 Supplicant PAE state machine. The 2020 revision renames it to "Supplicant PACP" and redefines the client interface to the Logon Process (Clause 8.4), with revised timers, variables, and counters (Clause 8.7). A rewrite would discard interoperable, well-tested behavior and risk broad regressions.

## Decision

Incrementally update `eapol_supp_sm.c` in-place: alias 2004 variable names to their 2020 equivalents, add the new Logon Process callback interface, and guard all 2020-specific behavior with `#ifdef CONFIG_IEEE8021X_2020`. Do not rewrite the state machine.

## Consequences

- **Positive**: Preserves the existing, interoperable state machine; lower regression risk; 2020 behavior is opt-in; existing API surface unchanged for non-opt-in builds.
- **Negative**: Variable aliasing and `#ifdef` guards can reduce code clarity; readers must map 2004→2020 names.
- **Mitigation**: Aliasing is documented at the declaration site; 2020 paths are exercised by PAE unit tests.

## Requirements Satisfied

- #5-#9 (REQ-F-PAE-001 through REQ-F-PAE-005)
- #10 (REQ-NF-PERF-001), #12 (REQ-NF-PAE-COMPAT-001)
