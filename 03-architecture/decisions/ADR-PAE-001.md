# ADR-PAE-001: Incremental Supplicant PACP State Machine Update

**GitHub Issue**: #34  
**Status**: Accepted  
**Date**: 2026-05-10

See [GitHub Issue #34](https://github.com/johnfu-ai/std_dev_practices-8021X-2020/issues/34) for full context, alternatives, and consequences.

## Summary

Incrementally update `eapol_supp_sm.c` in-place with variable aliasing, new Logon Process callback interface, and `#ifdef CONFIG_IEEE8021X_2020` guards. No rewrite.

## Requirements Satisfied

- #5-#9 (REQ-F-PAE-001 through REQ-F-PAE-005)
- #10 (REQ-NF-PERF-001), #12 (REQ-NF-PAE-COMPAT-001)
