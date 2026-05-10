# ARC-C-LOGON-001: Logon Process State Machine

**GitHub Issue**: TBD (create with label `architecture-component`)  
**Status**: Accepted  
**Date**: 2026-05-10

## Purpose

The Logon Process implements IEEE 802.1X-2020 Clause 12 — the NID-aware network selection and authentication orchestration layer that sits above the PACP and KaY state machines. It is the primary **new component** in Wave 1 and the most significant 802.1X-2020 addition to wpa_supplicant. The Logon Process selects a target Network Identity (NID), initiates PACP authentication for that NID, interprets the authentication outcome, and signals the Controlled Port (CP) to connect at the appropriate security level.

## Responsibilities

- Execute the Logon Process state machine per IEEE 802.1X-2020 Clause 12
- Manage NID selection: identify available NIDs from ANCP announcements or configuration, select the highest-priority matching NID
- Initiate EAPOL authentication for the selected NID by signalling PACP via `ieee802_1x_pacp_logon_if`
- Receive authentication outcome from PACP (success/failure) and translate to a CP connectivity signal
- Issue `connect_authenticated()` or `connect_secure()` to CP depending on NID security policy
- Manage Logon Process timers: network connect timeout, reauthentication period
- Expose a DI context struct (`ieee802_1x_logon_ctx`) for testability

## Source Files

| File | Role | Existence |
|------|------|-----------|
| `src/pae/ieee802_1x_logon.c` | Logon Process state machine | **NEW** |
| `src/pae/ieee802_1x_logon.h` | Public API and `ieee802_1x_logon_ctx` DI struct | **NEW** |
| `wpa_supplicant/wpas_logon.c` | Application bridge (wpa_supplicant → Logon Process) | **NEW** |

*Feature-gated by `CONFIG_IEEE8021X_2020_LOGON`. Per ADR-LOGON-001 (#37) and ADR-COMPAT-001 (#33).*

## Interfaces

### Provided Interface (API)

```c
/* Dependency-injection context — all cross-SM calls go through function pointers */
struct ieee802_1x_logon_ctx {
    void *ctx;                                          /* caller-supplied context */

    /* → PACP: initiate / terminate authentication */
    void (*logon_connect)(void *ctx);
    void (*logon_disconnect)(void *ctx);

    /* → CP: signal connectivity level */
    void (*cp_connect_authenticated)(void *ctx);
    void (*cp_connect_secure)(void *ctx);
    void (*cp_connect_pending)(void *ctx);
    void (*cp_connect_unauthenticated)(void *ctx);

    /* → KaY: start / stop MKA session for selected NID */
    int  (*kay_create_mka)(void *ctx, const struct mka_key_name *ckn,
                           const struct mka_key *cak, u32 life,
                           enum mka_created_mode mode);
    void (*kay_delete_mka)(void *ctx, struct ieee802_1x_mka_sci *sci);
};

/* Lifecycle */
struct ieee802_1x_logon *
ieee802_1x_logon_init(struct ieee802_1x_logon_ctx *ctx);
void ieee802_1x_logon_deinit(struct ieee802_1x_logon *logon);

/* Event pump — called by wpa_supplicant event loop */
void ieee802_1x_logon_sm_step(struct ieee802_1x_logon *logon);

/* External events */
void ieee802_1x_logon_port_enabled(struct ieee802_1x_logon *logon, bool enabled);
void ieee802_1x_logon_auth_success(struct ieee802_1x_logon *logon);
void ieee802_1x_logon_auth_failure(struct ieee802_1x_logon *logon);

/* NID management (CONFIG_IEEE8021X_2020_LOGON) */
int  ieee802_1x_logon_set_nid(struct ieee802_1x_logon *logon,
                               const u8 *nid, size_t nid_len);
```

### Required Interface (Dependencies)

| Dependency | Mechanism | Purpose |
|------------|-----------|---------|
| PACP (ARC-C-PACP-001) | `ieee802_1x_pacp_logon_if` callbacks registered at init | Start/stop PACP authentication |
| CP (ARC-C-CP-001) | `ieee802_1x_logon_ctx.cp_connect_*` function pointers | Signal port connectivity level |
| KaY (ARC-C-KAY-001) | `ieee802_1x_logon_ctx.kay_create_mka` / `kay_delete_mka` | Start/stop MKA for NID |
| wpa_supplicant event loop | `wpas_logon.c` bridge | Receive driver events, trigger `sm_step` |

All dependencies are injected via `ieee802_1x_logon_ctx` function pointers. No direct struct access across component boundaries. Per ADR-PAE-002 (#35).

## Build Integration

```makefile
# In wpa_supplicant/Makefile — guarded block
ifdef CONFIG_IEEE8021X_2020_LOGON
OBJS += ../src/pae/ieee802_1x_logon.o
OBJS += wpas_logon.o
CFLAGS += -DCONFIG_IEEE8021X_2020_LOGON
endif

# CONFIG_IEEE8021X_2020_LOGON implies CONFIG_IEEE8021X_2020
# Per feature flag hierarchy in ADR-COMPAT-001 (#33)
```

## Application Bridge: wpas_logon.c

`wpa_supplicant/wpas_logon.c` mirrors the existing `wpas_kay.c` pattern:

```c
/* Wire concrete wpa_supplicant callbacks into ieee802_1x_logon_ctx */
int wpas_logon_init(struct wpa_supplicant *wpa_s);
void wpas_logon_deinit(struct wpa_supplicant *wpa_s);
void wpas_logon_rx_eapol(struct wpa_supplicant *wpa_s,
                          const u8 *src_addr, const u8 *buf, size_t len);
```

The bridge allocates `ieee802_1x_logon_ctx`, populates all function pointers with concrete wpa_supplicant implementations, and calls `ieee802_1x_logon_init()`. It registers with the wpa_supplicant event loop to invoke `ieee802_1x_logon_sm_step()` on relevant events.

## Implementation Notes — Wave 1 Scope

Wave 1 Logon Process is a **minimal viable** implementation per ADR-LOGON-001 (#37):

1. **Single NID support**: Wave 1 targets one active NID at a time. Multi-NID group management (Clause 12.5) is Wave 3 scope (StR-007).
2. **Static NID configuration**: NID set via `ieee802_1x_logon_set_nid()` from wpa_supplicant config. ANCP-based dynamic NID discovery is Wave 3 (StR-004).
3. **State machine coverage**: DISCONNECTED → LOGON → AUTHENTICATING → AUTHENTICATED/SECURED states. Reauthentication and suspend paths included.
4. **No ANCP dependency**: ANCP (Wave 3 `ieee802_1x_ancp.c`) is not required for Wave 1 functionality.

## Traceability

| Link | Target | Type |
|------|--------|------|
| Implements | #3 (StR-003: Logon Process per Clause 12) | stakeholder requirement |
| Implements | #19 (REQ-F-LOGON-001: Logon Process state machine Clause 12) | requirement |
| Implements | #20 (REQ-F-LOGON-002: NID selection) | requirement |
| Implements | #21 (REQ-F-LOGON-003: PACP authentication initiation) | requirement |
| Implements | #22 (REQ-F-LOGON-004: CP connectivity signalling) | requirement |
| Satisfies | #23 (REQ-NF-LOGON-001: Logon Process mockable for unit tests) | non-functional |
| Governed by | #37 (ADR-LOGON-001: Logon Process as new SM in src/pae/) | decision |
| Governed by | #35 (ADR-PAE-002: Function-pointer DI for inter-SM interfaces) | decision |
| Governed by | #33 (ADR-COMPAT-001: CONFIG_IEEE8021X_2020_LOGON gate) | decision |
| Orchestrates | ARC-C-PACP-001 (authentication) | component |
| Orchestrates | ARC-C-CP-001 (connectivity signalling) | component |
| Orchestrates | ARC-C-KAY-001 (MKA session lifecycle) | component |

## Non-Goals

- Does not implement ANCP frame handling — Wave 3, `ieee802_1x_ancp.c` (separate component)
- Does not implement multi-NID group management — Wave 3 (StR-007)
- Does not implement Authenticator Logon Process — Supplicant role only in Wave 1
