# ARC-C-KAY-001: MKA Key Agreement Entity (KaY)

**GitHub Issue**: TBD (create with label `architecture-component`)  
**Status**: Accepted  
**Date**: 2026-05-10

## Purpose

The Key Agreement Entity (KaY) implements the MACsec Key Agreement (MKA) protocol as defined in IEEE 802.1X-2020 Clause 9. It negotiates Secure Association Keys (SAKs) between peer MKA participants, manages the MKA participant state machine, and drives the Controlled Port state machine (ARC-C-CP-001) via key distribution signals. It is the cryptographic core of MACsec-protected port access.

## Responsibilities

- Operate the MKA participant state machine per IEEE 802.1X-2020 Clause 9
- Transmit and receive MKPDU (MKA Protocol Data Unit) frames on the uncontrolled port
- Elect the Key Server among MKA participants
- Derive and distribute SAKs to peers via the Key Server role
- Manage MKA timers: Hello Time (2000 ms), Life Time (6000 ms), SAK Retire Time (3000 ms)
- Signal `newSAK`, `distributedKI/AN`, `electedSelf`, `chgdServer` events to ARC-C-CP-001
- Support MKA suspension (IEEE 802.1X-2020 new: Clause 9 suspension procedure)
- Support group CAK (IEEE 802.1X-2020 new: pre-shared group connectivity association key)
- Invoke SecY operations (ARC-C-SECY-001) to install cryptographic Security Associations

## Source Files

| File | Role |
|------|------|
| `src/pae/ieee802_1x_kay.c` | MKA participant state machine — extend in-place |
| `src/pae/ieee802_1x_kay.h` | Public API, `ieee802_1x_kay_ctx` DI struct, key/timer constants |
| `src/pae/ieee802_1x_kay_i.h` | Internal types (participant, peer, MKPDU structures) |
| `src/pae/ieee802_1x_key.c/h` | CAK/KEK/ICK/SAK derivation functions |

*All 802.1X-2020 additions are guarded by `#ifdef CONFIG_IEEE8021X_2020`. Per ADR-MKA-001 (#36).*

## Interfaces

### Provided Interface (API)

```c
/* Lifecycle */
struct ieee802_1x_kay *
ieee802_1x_kay_init(struct ieee802_1x_kay_ctx *ctx,
                    enum macsec_policy policy,
                    bool macsec_replay_protect,
                    u32 macsec_replay_window,
                    u16 port,
                    u8 priority,
                    u32 macsec_csindex);
void ieee802_1x_kay_deinit(struct ieee802_1x_kay *kay);

/* Event pump — called by timer/event loop */
void ieee802_1x_kay_run_state_machine(struct ieee802_1x_kay *kay);

/* Session management */
struct ieee802_1x_mka_participant *
ieee802_1x_kay_create_mka(struct ieee802_1x_kay *kay,
                           const struct mka_key_name *ckn,
                           const struct mka_key *cak,
                           u32 life,
                           enum mka_created_mode mode,
                           struct mka_key *rp_key,
                           bool is_authenticator);
void ieee802_1x_kay_delete_mka(struct ieee802_1x_kay *kay,
                                struct ieee802_1x_mka_sci *sci);

/* MKPDU receive entry point */
void ieee802_1x_kay_recv(struct ieee802_1x_kay *kay, const u8 *src_addr,
                          const u8 *buf, size_t len);

/* 802.1X-2020 additions (CONFIG_IEEE8021X_2020) */
int ieee802_1x_kay_suspend(struct ieee802_1x_kay *kay);    /* Clause 9 suspension */
int ieee802_1x_kay_resume(struct ieee802_1x_kay *kay);
```

### Required Interface (Dependencies)

| Dependency | Struct/Header | Purpose |
|------------|---------------|---------|
| `ieee802_1x_kay_ctx` | `src/pae/ieee802_1x_kay.h` | Function-pointer DI: driver callbacks for get_capability, enable_protect_frames, set_current_cipher_suite, etc. |
| SecY ops | `src/pae/ieee802_1x_secy_ops.h` | Install/remove SA in hardware via `secy_*` functions |
| CP SM | `src/pae/ieee802_1x_cp.h` | Signal key events: `ieee802_1x_cp_signal_newsak()`, `ieee802_1x_cp_set_electedself()`, etc. |
| L2 packet (uncontrolled) | `src/l2_packet/l2_packet.h` | MKPDU frame transmit/receive (EtherType 0x888E) |
| Crypto | `src/crypto/` | AES-CMAC, AES key wrap for CAK/KEK/ICK derivation |

## Build Integration

```makefile
# Enabled when CONFIG_MACSEC=y and CONFIG_MOKO=y (existing)
OBJS += ../src/pae/ieee802_1x_kay.o
OBJS += ../src/pae/ieee802_1x_key.o

# 802.1X-2020 suspension and group CAK additions inside:
# #ifdef CONFIG_IEEE8021X_2020
#   ieee802_1x_kay_suspend() / ieee802_1x_kay_resume()
#   group CAK participant creation
# #endif
```

## Implementation Notes — 802.1X-2020 Changes

Per ADR-MKA-001 (#36), the following in-place additions are required:

1. **MKA Suspension (Clause 9)**: new `ieee802_1x_kay_suspend()` / `ieee802_1x_kay_resume()` functions that freeze MKPDU transmission without tearing down the MKA session, guarded by `#ifdef CONFIG_IEEE8021X_2020`.
2. **Group CAK support**: `ieee802_1x_kay_create_mka()` extended to accept a group CAK (`rp_key`) for pre-shared multi-participant scenarios (Clause 9.3.3 update).
3. **No `ieee802_1x_kay_ctx` changes**: the SecY driver interface (`ieee802_1x_kay_ctx`) is intentionally left unchanged to preserve driver compatibility — per ADR-MKA-001 (#36).
4. **Timer constants unchanged**: `MKA_HELLO_TIME`, `MKA_LIFE_TIME`, `MKA_SAK_RETIRE_TIME` retain their defined values; 2020 revision does not change these normative values.

## Traceability

| Link | Target | Type |
|------|--------|------|
| Implements | #2 (StR-002: MACsec Key Agreement per Clause 9) | stakeholder requirement |
| Implements | #13 (REQ-F-MKA-001: MKA participant state machine) | requirement |
| Implements | #14 (REQ-F-MKA-002: Key Server election) | requirement |
| Implements | #15 (REQ-F-MKA-003: SAK derivation and distribution) | requirement |
| Implements | #16 (REQ-F-MKA-004: MKA timer management) | requirement |
| Implements | #17 (REQ-F-MKA-005: MKA suspension — 2020 new) | requirement |
| Satisfies | #18 (REQ-NF-MKA-001: Hello Time ≤2000 ms) | non-functional |
| Governed by | #36 (ADR-MKA-001: Incremental KaY update, no SecY interface changes) | decision |
| Governed by | #35 (ADR-PAE-002: Function-pointer DI pattern) | decision |
| Governed by | #33 (ADR-COMPAT-001: Compile-time feature gating) | decision |
| Drives | ARC-C-CP-001 (via key distribution signals) | component |
| Depends on | ARC-C-SECY-001 (SecY SA installation) | component |
| Wired by | `wpa_supplicant/wpas_kay.c` (application bridge) | bridge |

## Non-Goals

- Does not implement Clause 12 Logon Process — delegated to ARC-C-LOGON-001
- Does not implement MACsec frame encryption directly — that is the driver/SecY responsibility (ARC-C-SECY-001)
- Does not implement Authenticator KaY — wpa_supplicant operates as Supplicant only in Wave 1
