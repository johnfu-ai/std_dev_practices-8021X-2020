# ARC-C-CP-001: Controlled Port State Machine

**GitHub Issue**: TBD (create with label `architecture-component`)  
**Status**: Accepted  
**Date**: 2026-05-10

## Purpose

The Controlled Port (CP) state machine implements IEEE 802.1X-2020 Clause 10 (Controlled Port Management). It governs the transition of the MACsec-secured port through the sequence: DISCONNECTED → CONNECTED PENDING → CONNECTED UNAUTHENTICATED → CONNECTED AUTHENTICATED → CONNECTED SECURE. It acts as the arbiter between authentication results (from PACP/Logon Process) and MACsec key establishment (from KaY), enabling or disabling frame protection via SecY.

## Responsibilities

- Execute the CP state machine per IEEE 802.1X-2020 Clause 10 connectivity states
- Receive `connect*` signals from KaY (ARC-C-KAY-001) and, under 2020, from the Logon Process (ARC-C-LOGON-001)
- Receive SAK lifecycle events from KaY: `newSAK`, `distributedKI`, `distributedAN`, `chgdServer`, `electedSelf`
- Configure SecY (ARC-C-SECY-001) with the active cipher suite, confidentiality offset, replay protection settings, and port enable/disable
- Control whether the data plane uses unauthenticated, authenticated (MACsec-bypass), or encrypted (MACsec-protected) forwarding
- Track `usingReceiveSAs`, `allReceiving`, `serverTransmitting`, `usingTransmitAS` flags

## Source Files

| File | Role |
|------|------|
| `src/pae/ieee802_1x_cp.c` | CP state machine — extend in-place for 2020 Logon interface |
| `src/pae/ieee802_1x_cp.h` | Public API — connect signals, SAK lifecycle setters |

*Wave 1 scope: CP state machine is already implemented; changes are limited to accepting connect signals from Logon Process in addition to KaY. Full Clause 10 audit is Wave 2 (StR-006).*

## Interfaces

### Provided Interface (API)

```c
/* Lifecycle */
struct ieee802_1x_cp_sm *ieee802_1x_cp_sm_init(struct ieee802_1x_kay *kay);
void ieee802_1x_cp_sm_deinit(struct ieee802_1x_cp_sm *sm);

/* Event pump */
void ieee802_1x_cp_sm_step(void *cp_ctx);

/* Connectivity signals (from KaY or Logon Process) */
void ieee802_1x_cp_connect_pending(void *cp_ctx);
void ieee802_1x_cp_connect_unauthenticated(void *cp_ctx);
void ieee802_1x_cp_connect_authenticated(void *cp_ctx);
void ieee802_1x_cp_connect_secure(void *cp_ctx);

/* SAK lifecycle signals (from KaY) */
void ieee802_1x_cp_signal_chgdserver(void *cp_ctx);
void ieee802_1x_cp_set_electedself(void *cp_ctx, bool status);
void ieee802_1x_cp_set_ciphersuite(void *cp_ctx, u64 cs);
void ieee802_1x_cp_set_offset(void *cp_ctx, enum confidentiality_offset offset);
void ieee802_1x_cp_signal_newsak(void *cp_ctx);
void ieee802_1x_cp_set_distributedki(void *cp_ctx,
                                     const struct ieee802_1x_mka_ki *dki);
void ieee802_1x_cp_set_distributedan(void *cp_ctx, u8 an);
void ieee802_1x_cp_set_usingreceivesas(void *cp_ctx, bool status);
void ieee802_1x_cp_set_allreceiving(void *cp_ctx, bool status);
void ieee802_1x_cp_set_servertransmitting(void *cp_ctx, bool status);
void ieee802_1x_cp_set_usingtransmitas(void *cp_ctx, bool status);
```

### Required Interface (Dependencies)

| Dependency | Header | Purpose |
|------------|--------|---------|
| SecY ops | `src/pae/ieee802_1x_secy_ops.h` | Configure SecY: `secy_cp_control_*()` functions |
| KaY | `src/pae/ieee802_1x_kay.h` | CP is initialized with a `ieee802_1x_kay *` reference |
| Logon Process (new) | `src/pae/ieee802_1x_logon.h` | In Wave 1: Logon Process calls `connect_authenticated()` / `connect_secure()` via its `ieee802_1x_logon_ctx` |

## Build Integration

```makefile
# Enabled when CONFIG_MACSEC=y (existing, unchanged)
OBJS += ../src/pae/ieee802_1x_cp.o

# Wave 1 additions (minimal): accept connect signals from Logon Process
# These route through ieee802_1x_logon_ctx function pointers — no direct
# CP API change required. Per ADR-PAE-002 (#35).
```

## Implementation Notes — 802.1X-2020 Changes

Wave 1 changes to CP are minimal by design:

1. **Logon Process connect signals**: In 802.1X-2020, the Logon Process (Clause 12) is the orchestrator that calls `connect_authenticated()` / `connect_secure()` on the CP based on PACP outcome + NID policy. In Wave 1, the Logon Process (ARC-C-LOGON-001) bridges this signal via its `ieee802_1x_logon_ctx` function-pointer interface, requiring no changes to the CP API itself. The existing `ieee802_1x_cp_connect_authenticated()` and `ieee802_1x_cp_connect_secure()` entry points are reused.
2. **Full Clause 10 audit**: Deferred to Wave 2 (StR-006). Will verify all CP state variables and transitions against the 2020 revision for any delta from the 2010 baseline.

## Traceability

| Link | Target | Type |
|------|--------|------|
| Partially implements | #StR-006 (REQ for CP Clause 10 full update — Wave 2) | stakeholder requirement |
| Supports | #3 (StR-003: Logon Process — CP is a Logon orchestration target) | stakeholder requirement |
| Governed by | #35 (ADR-PAE-002: Function-pointer DI — Logon→CP via logon_ctx) | decision |
| Governed by | #33 (ADR-COMPAT-001: Compile-time feature gating) | decision |
| Receives signals from | ARC-C-KAY-001 (SAK lifecycle) | component |
| Receives signals from | ARC-C-LOGON-001 (connect_authenticated, connect_secure) | component |
| Controls | ARC-C-SECY-001 (SecY port enable/cipher/offset configuration) | component |

## Non-Goals

- Does not implement MKA key derivation — delegated to ARC-C-KAY-001
- Does not implement NID selection or Logon Process orchestration — delegated to ARC-C-LOGON-001
- Full Clause 10 delta audit is Wave 2 scope; Wave 1 changes are limited to Logon Process signal routing
