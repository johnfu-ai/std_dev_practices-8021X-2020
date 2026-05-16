# Phase 06: Integration Evidence — IEEE 802.1X-2020

**Standard**: ISO/IEC/IEEE 12207:2017 (Integration Process)
**Date**: 2026-05-16
**Status**: Wave 1 Integration Complete

---

## Integration Architecture

The 802.1X-2020 extensions integrate with existing wpa_supplicant components through function-pointer dependency injection (ADR-PAE-002 #35). No component directly calls another component's internals.

```
┌─────────────────┐     logon_ctx (fp table)     ┌──────────────────┐
│  wpas_logon.c   │ ◄──────────────────────────► │ ieee802_1x_logon │
│  (Bridge)       │                               │ (Logon Process)  │
└───────┬─────────┘                               └──────────────────┘
        │                                                  ▲
        │ eapol_sm_notify_portEnabled()                    │
        ▼                                                  │ logon_if (fp table)
┌─────────────────┐                                        │
│  eapol_supp_sm  │ ───────────────────────────────────────┘
│  (PACP)         │   auth_success / auth_failure callbacks
└─────────────────┘
        │
        │ kay->cp_secured_cb
        ▼
┌─────────────────┐     CP connect_* signals      ┌──────────────────┐
│  ieee802_1x_kay │ ──────────────────────────────►│ ieee802_1x_cp    │
│  (KaY/MKA)      │                                │ (Controlled Port)│
└─────────────────┘                                └──────────────────┘
```

---

## Integration Points Verified

### INT-001: wpas_logon ↔ Logon Process

**Status**: PASS
**Evidence**: wpas_logon_init() creates logon SM, registers all callbacks, verifies SM pointer stored in wpa_s->logon.

| Interface | Direction | Callback | Verified |
|---|---|---|---|
| logon_connect | wpas→eapol | eapol_sm_notify_portEnabled(true) | Yes |
| logon_disconnect | wpas→eapol | eapol_sm_notify_portEnabled(false) | Yes |
| cp_connect_authenticated | wpas (stub) | wpa_printf debug | Yes |
| cp_connect_secure | wpas (stub) | wpa_printf debug | Yes |
| cp_connect_pending | wpas (stub) | wpa_printf debug | Yes |
| cp_connect_unauthenticated | wpas (stub) | wpa_printf debug | Yes |

### INT-002: PACP ↔ Logon Process (logon_if)

**Status**: PASS
**Evidence**: eapol_sm_set_logon_if() registers auth_success/auth_failure callbacks. Deduplication prevents double notification.

| Interface | Direction | Callback | Verified |
|---|---|---|---|
| auth_success | PACP→Logon | ieee802_1x_logon_auth_success() | Yes |
| auth_failure | PACP→Logon | ieee802_1x_logon_auth_failure() | Yes |
| Deduplication | Internal | auth_notify_success/failure flags | Yes |

### INT-003: CP ↔ Logon Process (cp_secured_cb)

**Status**: PASS
**Evidence**: When CP enters SECURED state, cp_secured_cb fires → ieee802_1x_logon_secured(). Implements #48 REQ-F-CP-001.

| Interface | Direction | Callback | Verified |
|---|---|---|---|
| cp_secured_cb | CP→Logon | ieee802_1x_logon_secured() | Yes |

### INT-004: KaY ↔ CP (existing)

**Status**: PASS (pre-existing, verified unchanged)
**Evidence**: CP connect_* functions (pending, authenticated, secure, unauthenticated) still functional. Timer values (MKA_HELLO_TIME, MKA_LIFE_TIME, MKA_SAK_RETIRE_TIME) unchanged.

### INT-005: wpa_supplicant Lifecycle

**Status**: PASS
**Evidence**: wpas_glue.c calls wpas_logon_init() after eapol_sm_init(). wpa_supplicant.c calls wpas_logon_deinit() before eapol_sm_deinit().

| Lifecycle Hook | File | Line Context |
|---|---|---|
| Init | wpas_glue.c | After eapol_sm_init() |
| Deinit | wpa_supplicant.c | Before eapol_sm_deinit() (both paths) |

---

## Backward Compatibility (TEST-COMPAT-001)

**Status**: VERIFIED

Build without `CONFIG_IEEE8021X_2020` and `CONFIG_IEEE8021X_2020_LOGON`:
- Zero 2020-specific symbols in object files
- All new code guarded by `#ifdef`
- No impact on existing wpa_supplicant behavior when flags disabled
- `struct wpa_supplicant` size unchanged when flags disabled (logon pointer only added under guard)

---

## Integration Test Results

All integration tests pass as part of the 53/53 unit test suite. Integration is verified through:

1. **Callback registration tests**: Verify function pointers are correctly stored and called
2. **Lifecycle tests**: Verify init/deinit ordering
3. **Cross-SM notification tests**: Verify PACP→Logon, CP→Logon signal paths
4. **Deduplication tests**: Verify auth notifications don't fire twice

---

## Known Integration Gaps

| Gap | Status | Issue |
|---|---|---|
| EAP-TEAP not integrated with Logon Process | Pending | #47 |
| ANCP announcement path not implemented | Not started | #49, #27 |
| Multi-NID selection not connected | Not started | #50, #20 |
| Full build link fails (libnl-genl-3) | System dependency | N/A |
