# ARC-C-PACP-001: Supplicant PACP State Machine

**GitHub Issue**: TBD (create with label `architecture-component`)  
**Status**: Accepted  
**Date**: 2026-05-10

## Purpose

The Supplicant Port Access Control Protocol (PACP) state machine is the IEEE 802.1X-2020 Clause 8 implementation for the client (supplicant) side of port-based network access control. It manages the authentication lifecycle of a controlled port, driving EAP exchanges and signalling authentication status to the Logon Process and the rest of the system.

## Responsibilities

- Execute the Supplicant PAE state machine as specified in IEEE 802.1X-2020 Clause 8.3 (CONNECTING, AUTHENTICATING, AUTHENTICATED, HELD, RESTART states)
- Manage EAPOL frame send/receive via the Layer-2 packet abstraction
- Invoke the EAP peer state machine for credential exchange
- Expose a Logon Process callback interface (`ieee802_1x_pacp_logon_if`) so the Logon Process (ARC-C-LOGON-001) can initiate and terminate authentication per Clause 12
- Enforce authWhileCounter (heldPeriod) and startWhen/quietWhile timers
- Report `portStatus` (Authorized/Unauthorized) to the application layer

## Source Files

| File | Role |
|------|------|
| `src/eapol_supp/eapol_supp_sm.c` | Core state machine implementation — extend in-place |
| `src/eapol_supp/eapol_supp_sm.h` | Public API and context struct definitions |

*No new files created; all 802.1X-2020 additions are guarded by `#ifdef CONFIG_IEEE8021X_2020`. Per ADR-PAE-001 (#34).*

## Interfaces

### Provided Interface (API)

```c
/* Lifecycle */
struct eapol_sm *eapol_sm_init(struct eapol_ctx *ctx);
void eapol_sm_deinit(struct eapol_sm *sm);

/* Event pump — called by event loop */
void eapol_sm_step(struct eapol_sm *sm);

/* External triggers */
void eapol_sm_notify_portEnabled(struct eapol_sm *sm, bool enabled);
void eapol_sm_notify_portValid(struct eapol_sm *sm, bool valid);
void eapol_sm_notify_eap_success(struct eapol_sm *sm, bool success);
void eapol_sm_notify_eap_fail(struct eapol_sm *sm);
void eapol_sm_notify_lower_layer_success(struct eapol_sm *sm, int in_4way);

/* 802.1X-2020 addition: Logon Process callback interface (CONFIG_IEEE8021X_2020) */
struct ieee802_1x_pacp_logon_if {
    void (*logon_connect)(void *ctx);      /* Logon Process → PACP: initiate auth */
    void (*logon_disconnect)(void *ctx);   /* Logon Process → PACP: terminate auth */
    void *ctx;
};
void eapol_sm_set_logon_if(struct eapol_sm *sm,
                            const struct ieee802_1x_pacp_logon_if *logon_if);
```

### Required Interface (Dependencies)

| Dependency | Header | Purpose |
|------------|--------|---------|
| EAP peer SM | `src/eap_peer/eap.h` | Drives EAP method exchange |
| L2 packet | `src/l2_packet/l2_packet.h` | EAPOL frame send/receive |
| Logon Process (new) | `src/pae/ieee802_1x_logon.h` | Callback notification on auth result |
| `eapol_ctx` callbacks | `src/eapol_supp/eapol_supp_sm.h` | Application-layer notifications (eapSuccess, eapFail, etc.) |

## Build Integration

```makefile
# Enabled when CONFIG_IEEE8021X_EAPOL=y (existing, unchanged)
OBJS += ../src/eapol_supp/eapol_supp_sm.o

# 802.1X-2020 variable extensions are inside:
# #ifdef CONFIG_IEEE8021X_2020
#   ... new Clause 8 variables, pacp_logon_if callbacks
# #endif
```

## Implementation Notes — 802.1X-2020 Changes

Per ADR-PAE-001 (#34), the following in-place additions are required:

1. **New state variables** (Clause 8.3): `reAuthenticate`, `eapolEap`, `eapSuccess`, `eapFail` already present; add `eapStart` NID variant, `PACP_NID` association flag (guarded).
2. **`ieee802_1x_pacp_logon_if` callback struct**: new — allows Logon Process (Clause 12) to connect/disconnect the port without bypassing the PAE state machine.
3. **Variable aliasing**: where 802.1X-2020 renames a variable (e.g., PACP replaces PAE), expose the new name as a macro alias to avoid breaking callers.
4. **`authWhileCounter` reset**: reset on `logon_connect()` signal, not only on port enable/disable.

All changes wrapped in `#ifdef CONFIG_IEEE8021X_2020`.

## Traceability

| Link | Target | Type |
|------|--------|------|
| Implements | #5 (REQ-F-PAE-001: Supplicant PAE state machine Clause 8.3) | requirement |
| Implements | #6 (REQ-F-PAE-002: PACP variables 2020) | requirement |
| Implements | #7 (REQ-F-PAE-003: heldPeriod, quietWhile timers) | requirement |
| Implements | #8 (REQ-F-PAE-004: portStatus reporting) | requirement |
| Implements | #9 (REQ-F-PAE-005: Logon Process interface) | requirement |
| Satisfies | #10 (REQ-NF-PERF-001: EAPOL response <100ms p95) | non-functional |
| Satisfies | #12 (REQ-NF-PAE-COMPAT-001: zero change when flag disabled) | non-functional |
| Governed by | #34 (ADR-PAE-001: Incremental PACP update strategy) | decision |
| Governed by | #35 (ADR-PAE-002: Function-pointer DI pattern) | decision |
| Governed by | #33 (ADR-COMPAT-001: Compile-time feature gating) | decision |
| Called by | ARC-C-LOGON-001 | component |
| Calls | EAP peer (ARC-C-EAP, outside Wave 1 scope) | component |

## Non-Goals

- Does not implement the Authenticator PAE (`src/eapol_auth/`) — separate component, out of Wave 1 scope
- Does not manage MKA key derivation — delegated to ARC-C-KAY-001
- Does not implement Clause 12 Logon Process logic — that belongs to ARC-C-LOGON-001
