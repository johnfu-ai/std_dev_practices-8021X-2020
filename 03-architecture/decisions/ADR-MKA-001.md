# ADR-MKA-001: Incremental MKA (KaY) Update to IEEE 802.1X-2020 Clause 9

**GitHub Issue**: #36  
**Status**: Accepted  
**Date**: 2026-05-10

See [GitHub Issue #36](https://github.com/johnfu-ai/std_dev_practices-8021X-2020/issues/36) for full context, alternatives, and consequences.

## Summary

Incrementally update `ieee802_1x_kay.c` in-place. New 2020 features (suspension, group CAK) added as guarded functions. No changes to `ieee802_1x_kay_ctx` (SecY interface unchanged).

## Requirements Satisfied

- #2 (StR-002), #13-#18 (REQ-F-MKA-001 through REQ-NF-MKA-001)
