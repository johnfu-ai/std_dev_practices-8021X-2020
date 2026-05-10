# ADR-ARCH-001: Extend wpa_supplicant In-Place

**GitHub Issue**: #32  
**Status**: Accepted  
**Date**: 2026-05-10

See [GitHub Issue #32](https://github.com/johnfu-ai/std_dev_practices-8021X-2020/issues/32) for full context, alternatives, and consequences.

## Summary

Extend wpa_supplicant in-place (not a separate library) for IEEE 802.1X-2020 compliance. Modify existing `src/pae/`, `src/eapol_supp/` files and add new files within the existing source tree.

## Requirements Satisfied

- #1 (StR-001), #2 (StR-002), #3 (StR-003), #4 (StR-008)
- #24 (REQ-NF-COMPAT-001)
