# ADR-COMPAT-001: Compile-Time Feature Gating Strategy

**GitHub Issue**: #33  
**Status**: Accepted  
**Date**: 2026-05-10

See [GitHub Issue #33](https://github.com/johnfu-ai/std_dev_practices-8021X-2020/issues/33) for full context, alternatives, and consequences.

## Summary

Layered compile-time gating: `CONFIG_IEEE8021X_2020` (master) with optional sub-flags (`CONFIG_IEEE8021X_2020_LOGON`, `CONFIG_IEEE8021X_2020_ANCP`). Zero impact when flags are disabled.

## Requirements Satisfied

- #4 (StR-008), #24 (REQ-NF-COMPAT-001), #25 (REQ-NF-COMPAT-002), #26 (REQ-NF-COMPAT-003)
