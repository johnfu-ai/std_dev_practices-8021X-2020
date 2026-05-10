# ARC-C-SECY-001: SecY Operations Abstraction

**GitHub Issue**: TBD (create with label `architecture-component`)  
**Status**: Accepted  
**Date**: 2026-05-10

## Purpose

The SecY Operations Abstraction is the hardware/driver interface layer that translates CP and KaY control requests into concrete MACsec hardware operations. It decouples the protocol state machines (ARC-C-CP-001, ARC-C-KAY-001) from driver-specific MACsec implementations. SecY in IEEE 802.1AE terminology is the MAC Security Entity — the component that performs per-frame encryption, authentication, and replay protection on the data plane.

## Responsibilities

- Initialize and deinitialize the MACsec hardware or kernel subsystem via `secy_init_macsec()` / `secy_deinit_macsec()`
- Accept CP control commands: validate-frames policy, protect-frames enable, encryption enable, replay window, offload mode, cipher suite, confidentiality offset, port enable/disable
- Accept KaY SA management commands: create/delete/enable/disable Receive SCs, Receive SAs, Transmit SCs, Transmit SAs
- Accept KaY PN management commands: get/set next PN, get lowest PN
- Route all commands through the `ieee802_1x_kay_ctx` function-pointer interface to the actual driver implementation
- Provide a stable API surface so neither CP nor KaY need to know about the underlying driver model

## Source Files

| File | Role |
|------|------|
| `src/pae/ieee802_1x_secy_ops.c` | Thin dispatch layer — calls `kay->ctx->*` function pointers |
| `src/pae/ieee802_1x_secy_ops.h` | Public API — all `secy_*` function declarations |

*This component is intentionally a thin dispatch shim. No 802.1X-2020 changes required to this layer. Per ADR-MKA-001 (#36): `ieee802_1x_kay_ctx` (the driver callback struct) is left unchanged.*

## Interfaces

### Provided Interface (API)

```c
/* Lifecycle */
int secy_init_macsec(struct ieee802_1x_kay *kay);
int secy_deinit_macsec(struct ieee802_1x_kay *kay);

/* CP → SecY: port control */
int secy_cp_control_validate_frames(struct ieee802_1x_kay *kay,
                                    enum validate_frames vf);
int secy_cp_control_protect_frames(struct ieee802_1x_kay *kay, bool flag);
int secy_cp_control_encrypt(struct ieee802_1x_kay *kay, bool enabled);
int secy_cp_control_replay(struct ieee802_1x_kay *kay, bool flag, u32 win);
int secy_cp_control_offload(struct ieee802_1x_kay *kay, u8 offload);
int secy_cp_control_current_cipher_suite(struct ieee802_1x_kay *kay, u64 cs);
int secy_cp_control_confidentiality_offset(struct ieee802_1x_kay *kay,
                                           enum confidentiality_offset co);
int secy_cp_control_enable_port(struct ieee802_1x_kay *kay, bool flag);

/* KaY → SecY: capability query */
int secy_get_capability(struct ieee802_1x_kay *kay, enum macsec_cap *cap);

/* KaY → SecY: PN management */
int secy_get_receive_lowest_pn(struct ieee802_1x_kay *kay,
                               struct receive_sa *rxsa);
int secy_get_transmit_next_pn(struct ieee802_1x_kay *kay,
                              struct transmit_sa *txsa);
int secy_set_transmit_next_pn(struct ieee802_1x_kay *kay,
                              struct transmit_sa *txsa);
int secy_set_receive_lowest_pn(struct ieee802_1x_kay *kay,
                               struct receive_sa *txsa);

/* KaY → SecY: Receive SC/SA lifecycle */
int secy_create_receive_sc(struct ieee802_1x_kay *kay, struct receive_sc *rxsc);
int secy_delete_receive_sc(struct ieee802_1x_kay *kay, struct receive_sc *rxsc);
int secy_create_receive_sa(struct ieee802_1x_kay *kay, struct receive_sa *rxsa);
int secy_delete_receive_sa(struct ieee802_1x_kay *kay, struct receive_sa *rxsa);
int secy_enable_receive_sa(struct ieee802_1x_kay *kay, struct receive_sa *rxsa);
int secy_disable_receive_sa(struct ieee802_1x_kay *kay, struct receive_sa *rxsa);

/* KaY → SecY: Transmit SC/SA lifecycle */
int secy_create_transmit_sc(struct ieee802_1x_kay *kay,
                            struct transmit_sc *txsc);
int secy_delete_transmit_sc(struct ieee802_1x_kay *kay,
                            struct transmit_sc *txsc);
int secy_create_transmit_sa(struct ieee802_1x_kay *kay,
                            struct transmit_sa *txsa);
int secy_delete_transmit_sa(struct ieee802_1x_kay *kay,
                            struct transmit_sa *txsa);
int secy_enable_transmit_sa(struct ieee802_1x_kay *kay,
                            struct transmit_sa *txsa);
int secy_disable_transmit_sa(struct ieee802_1x_kay *kay,
                             struct transmit_sa *txsa);
```

### Required Interface (Dependencies)

| Dependency | Mechanism | Purpose |
|------------|-----------|---------|
| Driver MACsec backend | `ieee802_1x_kay_ctx` function pointers | Concrete SA install/remove via `ctx->create_receive_sa()`, etc. |
| `wpa_supplicant/wpas_kay.c` | Populates `ieee802_1x_kay_ctx` at init | Wires Linux MACsec driver or macsec_qca driver callbacks |

The `ieee802_1x_kay_ctx` struct (defined in `ieee802_1x_kay.h`) is the **single integration point** between the protocol stack and the hardware. SecY ops are a compile-time stable API; driver authors implement the ctx callbacks.

## Build Integration

```makefile
# Enabled when CONFIG_MACSEC=y (existing, unchanged)
OBJS += ../src/pae/ieee802_1x_secy_ops.o

# No new build flags required for Wave 1.
# ieee802_1x_kay_ctx interface is frozen per ADR-MKA-001 (#36).
```

## Implementation Notes — 802.1X-2020 Changes

**No changes required in Wave 1.** ADR-MKA-001 (#36) explicitly decided to leave `ieee802_1x_kay_ctx` unchanged to preserve driver compatibility. The SecY abstraction was already well-designed in the 2010 baseline.

Future consideration (Wave 2/3): if Clause 10 audit (StR-006) identifies new SecY operations needed for 802.1X-2020 (e.g., extended PN handling for XPN cipher suites), they will be added as new optional function pointers in `ieee802_1x_kay_ctx` with NULL guards, maintaining backward compatibility.

## Traceability

| Link | Target | Type |
|------|--------|------|
| Supports | #2 (StR-002: MACsec Key Agreement — SecY installs KaY-derived SAs) | stakeholder requirement |
| Supports | #15 (REQ-F-MKA-003: SAK distribution — SecY installs the SAK into hardware) | requirement |
| Governed by | #36 (ADR-MKA-001: No SecY interface changes) | decision |
| Governed by | #35 (ADR-PAE-002: Function-pointer DI — `ieee802_1x_kay_ctx`) | decision |
| Governed by | #33 (ADR-COMPAT-001: Compile-time feature gating) | decision |
| Invoked by | ARC-C-CP-001 (port control commands) | component |
| Invoked by | ARC-C-KAY-001 (SA lifecycle commands) | component |
| Dispatches to | Driver (hardware MACsec: macsec_linux, macsec_qca, etc.) | external |

## Non-Goals

- Does not implement MACsec frame encryption directly — that is the driver/kernel responsibility
- Does not implement MKA protocol — delegated to ARC-C-KAY-001
- Does not change the `ieee802_1x_kay_ctx` interface in Wave 1 — any extension deferred to Wave 2+
