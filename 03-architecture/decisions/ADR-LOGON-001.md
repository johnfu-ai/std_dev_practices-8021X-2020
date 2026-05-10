# ADR-LOGON-001: Logon Process as New State Machine Module in src/pae/

**GitHub Issue**: #37  
**Status**: Accepted  
**Date**: 2026-05-10

See [GitHub Issue #37](https://github.com/johnfu-ai/std_dev_practices-8021X-2020/issues/37) for full context, alternatives, and consequences.

## Summary

Logon Process implemented as `src/pae/ieee802_1x_logon.c/h` — a first-class state machine with `ieee802_1x_logon_ctx` for DI. Bridge file `wpa_supplicant/wpas_logon.c` mirrors `wpas_kay.c` pattern. Feature-gated by `CONFIG_IEEE8021X_2020_LOGON`.

## Requirements Satisfied

- #3 (StR-003), #19-#23 (REQ-F-LOGON-001 through REQ-NF-LOGON-001)
