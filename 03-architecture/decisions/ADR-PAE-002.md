# ADR-PAE-002: Function-Pointer Dependency Injection for Inter-SM Interfaces

**GitHub Issue**: #35  
**Status**: Accepted  
**Date**: 2026-05-10

See [GitHub Issue #35](https://github.com/johnfu-ai/std_dev_practices-8021X-2020/issues/35) for full context, alternatives, and consequences.

## Summary

Use function-pointer context structs (established wpa_supplicant pattern from `ieee802_1x_kay_ctx`) for all new inter-SM interfaces: `ieee802_1x_logon_ctx`, `ieee802_1x_pacp_logon_if`. Bridge files (`wpas_logon.c`) wire concrete implementations.

## Requirements Satisfied

- #6 (REQ-F-PAE-002), #11 (REQ-NF-TEST-001), #19 (REQ-F-LOGON-001), #21 (REQ-F-LOGON-003), #23 (REQ-NF-LOGON-001)
