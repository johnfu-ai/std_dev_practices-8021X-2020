# DESIGN-MKA-001: MKA 2020 Update Design

| Field | Value |
|-------|-------|
| Status | Draft |
| Date | 2026-05-16 |
| Implements | REQ-F-MKA-001 (#13), REQ-F-MKA-002 (#14), REQ-F-MKA-003 (#15), REQ-F-MKA-004 (#16), REQ-F-MKA-005 (#17) |
| Governed By | ADR-MKA-001 (#36), ADR-PAE-002 (#35), ADR-COMPAT-001 (#33), ADR-ARCH-001 (#32) |

## 1. Overview

This document specifies the design for updating the MACsec Key Agreement (MKA) implementation in `src/pae/ieee802_1x_kay.c` to comply with IEEE 802.1X-2020 Clause 9. Per ADR-MKA-001 (#36), all changes are incremental in-place additions, guarded by `#ifdef CONFIG_IEEE8021X_2020`. The `ieee802_1x_kay_ctx` driver interface is intentionally left unchanged.

The two substantive 802.1X-2020 additions for MKA are:
1. **MKA Suspension/Resume** (Clause 9): Freeze MKPDU transmission without tearing down the MKA session.
2. **Group CAK Support** (Clause 9.3.3 update): Pre-shared group Connectivity Association Key for multi-participant scenarios.

## 2. MKA Suspension and Resume

### 2.1 Concept

IEEE 802.1X-2020 Clause 9 introduces the ability to suspend an MKA session. When suspended, the participant stops transmitting MKPDUs and stops the Hello timer, but retains its peer state, SAK state, and participant data. Resume re-enables MKPDU transmission and restarts the Hello timer.

This is distinct from `ieee802_1x_kay_delete_mka`, which tears down the entire participant. Suspension preserves the session for rapid re-establishment.

### 2.2 Data Structure Additions

```c
/* Inside struct ieee802_1x_mka_participant (ieee802_1x_kay_i.h) */

#ifdef CONFIG_IEEE8021X_2020
    bool suspended;              /* True when MKA session is suspended */
    struct os_time suspend_time; /* Timestamp when suspension began */
#endif /* CONFIG_IEEE8021X_2020 */
```

```c
/* Inside struct ieee802_1x_kay (ieee802_1x_kay.h) */

#ifdef CONFIG_IEEE8021X_2020
    bool mka_suspended;          /* Global flag: at least one participant suspended */
#endif /* CONFIG_IEEE8021X_2020 */
```

### 2.3 New Function Signatures

```c
/**
 * ieee802_1x_kay_suspend - Suspend MKA session for all participants
 * @kay: KaY state machine pointer.
 * Returns: 0 on success, -1 on failure.
 *
 * Per IEEE 802.1X-2020 Clause 9 suspension procedure:
 * - Sets participant->suspended = true for all active participants
 * - Stops MKPDU transmission (skip in kay_run_state_machine)
 * - Stops the Hello timer for suspended participants
 * - Retains peer state, SAK state, and participant data
 *
 * Guarded by #ifdef CONFIG_IEEE8021X_2020.
 *
 * @implements #17 REQ-F-MKA-005
 * @governed #36 ADR-MKA-001
 */
#ifdef CONFIG_IEEE8021X_2020
int ieee802_1x_kay_suspend(struct ieee802_1x_kay *kay);
#endif /* CONFIG_IEEE8021X_2020 */

/**
 * ieee802_1x_kay_resume - Resume a previously suspended MKA session
 * @kay: KaY state machine pointer.
 * Returns: 0 on success, -1 on failure.
 *
 * Per IEEE 802.1X-2020 Clause 9 resume procedure:
 * - Clears participant->suspended for all participants
 * - Restarts the Hello timer
 * - Resumes MKPDU transmission on next kay_run_state_machine call
 *
 * Guarded by #ifdef CONFIG_IEEE8021X_2020.
 *
 * @implements #17 REQ-F-MKA-005
 * @governed #36 ADR-MKA-001
 */
#ifdef CONFIG_IEEE8021X_2020
int ieee802_1x_kay_resume(struct ieee802_1x_kay *kay);
#endif /* CONFIG_IEEE8021X_2020 */
```

### 2.4 Internal Helper Functions (static)

```c
/**
 * kay_suspend_participant - Suspend a single MKA participant
 * @participant: MKA participant pointer.
 *
 * Sets suspended flag, records suspend_time, cancels the participant's
 * Hello timer registration in eloop.
 */
#ifdef CONFIG_IEEE8021X_2020
static void kay_suspend_participant(struct ieee802_1x_mka_participant *participant);
#endif

/**
 * kay_resume_participant - Resume a single MKA participant
 * @participant: MKA participant pointer.
 *
 * Clears suspended flag, restarts the Hello timer, marks the
 * participant as needing to transmit (enable_new_info = true).
 */
#ifdef CONFIG_IEEE8021X_2020
static void kay_resume_participant(struct ieee802_1x_mka_participant *participant);
#endif
```

### 2.5 Integration Points in Existing Code

The following existing functions in `ieee802_1x_kay.c` require guarded additions:

| Function | Change | Guard |
|----------|--------|-------|
| `ieee802_1x_kay_run_state_machine()` | Skip MKPDU transmission when `participant->suspended == true` | `#ifdef CONFIG_IEEE8021X_2020` |
| `ieee802_1x_kay_create_mka()` | Initialize `suspended = false` in new participant | `#ifdef CONFIG_IEEE8021X_2020` |
| `kay_delete_mka()` | No change needed; deletion implicitly ends suspension | -- |
| `ieee802_1x_kay_deinit()` | Clean up suspended state during full teardown | `#ifdef CONFIG_IEEE8021X_2020` |

In `ieee802_1x_kay_run_state_machine()`, the suspension check is inserted before the MKPDU transmit logic:

```c
/* Inside the participant loop in kay_run_state_machine() */
#ifdef CONFIG_IEEE8021X_2020
    if (participant->suspended) {
        wpa_printf(MSG_DEBUG, "KAY: participant suspended, skipping MKPDU tx");
        continue;
    }
#endif
```

### 2.6 Suspension State Machine Interactions

The existing MKA participant state machine (in `kay_run_state_machine()`) processes participants in a loop. The suspension feature inserts a `continue` guard at the top of this loop. The rest of the state machine logic (peer discovery, key server election, SAK distribution) is unchanged when the participant is not suspended.

| State Machine Step | Change When Suspended | Guard |
|--------------------|-----------------------|-------|
| MKPDU transmission | Skipped | `if (participant->suspended) continue;` |
| MKPDU reception | Still processed | No change |
| Peer expiry (life timer) | Still processed; peers may expire during suspension | No change |
| SAK distribution | Skipped (no transmission) | Covered by MKPDU tx skip |
| Hello timer | Stopped at suspend; restarted at resume | `eloop_cancel_timeout` / `eloop_register_timeout` |

Reception is intentionally not blocked during suspension. The participant continues to process inbound MKPDUs to keep peer state current. This prevents peer expiry during short suspensions.

## 3. Group CAK Support

### 3.1 Concept

IEEE 802.1X-2020 Clause 9.3.3 update adds support for a pre-shared group Connectivity Association Key (group CAK). This enables scenarios where multiple supplicants share a pre-configured CAK for a connectivity association, rather than deriving the CAK from an EAP exchange. The group CAK is passed as an additional parameter during MKA participant creation.

### 3.2 Data Structure Additions

```c
/* Inside struct ieee802_1x_mka_participant (ieee802_1x_kay_i.h) */

#ifdef CONFIG_IEEE8021X_2020
    bool is_group_cak;             /* True if CAK is a pre-shared group CAK */
    struct mka_key rp_key;         /* Resilience Passthrough key (group CAK) */
    bool rp_key_set;               /* True if rp_key has been populated */
#endif /* CONFIG_IEEE8021X_2020 */
```

### 3.3 Extended Function Signature

The existing `ieee802_1x_kay_create_mka` function signature in `ieee802_1x_kay.h` is extended with an additional parameter. To maintain backward compatibility, the new parameter is added under the `CONFIG_IEEE8021X_2020` guard with a separate function.

```c
/**
 * ieee802_1x_kay_create_mka - Create an MKA participant
 * @kay: KaY state machine pointer.
 * @ckn: CAK Name.
 * @cak: Connectivity Association Key.
 * @life: MKA life time in milliseconds.
 * @mode: Creation mode (PSK or EAP_EXCHANGE).
 * @is_authenticator: True if this participant acts as authenticator.
 * Returns: Pointer to new participant, or NULL on failure.
 *
 * Existing signature preserved for backward compatibility.
 * 802.1X-2020 callers should use ieee802_1x_kay_create_mka_2020()
 * to provide the group CAK (rp_key).
 */
struct ieee802_1x_mka_participant *
ieee802_1x_kay_create_mka(struct ieee802_1x_kay *kay,
                           const struct mka_key_name *ckn,
                           const struct mka_key *cak,
                           u32 life, enum mka_created_mode mode,
                           bool is_authenticator);

#ifdef CONFIG_IEEE8021X_2020
/**
 * ieee802_1x_kay_create_mka_2020 - Create MKA participant with 2020 extensions
 * @kay: KaY state machine pointer.
 * @ckn: CAK Name.
 * @cak: Connectivity Association Key.
 * @life: MKA life time in milliseconds.
 * @mode: Creation mode (PSK or EAP_EXCHANGE).
 * @is_authenticator: True if this participant acts as authenticator.
 * @rp_key: Pre-shared group CAK key (may be NULL if not applicable).
 * Returns: Pointer to new participant, or NULL on failure.
 *
 * Extended version of ieee802_1x_kay_create_mka() for 802.1X-2020.
 * Sets participant->is_group_cak and stores rp_key if provided.
 *
 * @implements #15 REQ-F-MKA-003 (group CAK per Clause 9.3.3 update)
 * @governed #36 ADR-MKA-001
 */
struct ieee802_1x_mka_participant *
ieee802_1x_kay_create_mka_2020(struct ieee802_1x_kay *kay,
                                const struct mka_key_name *ckn,
                                const struct mka_key *cak,
                                u32 life, enum mka_created_mode mode,
                                bool is_authenticator,
                                const struct mka_key *rp_key);

/**
 * ieee802_1x_kay_create_mka - Backward-compatible wrapper
 *
 * Delegates to ieee802_1x_kay_create_mka_2020() with rp_key = NULL.
 * This preserves the existing public API.
 */
static inline struct ieee802_1x_mka_participant *
ieee802_1x_kay_create_mka_compat(struct ieee802_1x_kay *kay,
                                  const struct mka_key_name *ckn,
                                  const struct mka_key *cak,
                                  u32 life, enum mka_created_mode mode,
                                  bool is_authenticator)
{
    return ieee802_1x_kay_create_mka_2020(kay, ckn, cak, life, mode,
                                           is_authenticator, NULL);
}
#endif /* CONFIG_IEEE8021X_2020 */
```

### 3.4 Group CAK Key Derivation Path

When `is_group_cak == true`, the participant uses the group CAK as the CAK for key derivation (KEK, ICK) instead of deriving the CAK from the EAP MSK. The key derivation functions in `ieee802_1x_key.c` remain unchanged; the difference is at the participant creation level where the CAK is populated.

In the `ieee802_1x_kay_create_mka_2020()` implementation:

```c
#ifdef CONFIG_IEEE8021X_2020
    if (rp_key && rp_key->len > 0) {
        participant->is_group_cak = true;
        os_memcpy(participant->rp_key.key, rp_key->key, rp_key->len);
        participant->rp_key.len = rp_key->len;
        participant->rp_key_set = true;
    }
#endif
```

### 3.5 Group CAK Interaction with SAK Distribution

When a participant with `is_group_cak == true` is elected Key Server, the SAK distribution procedure uses the group CAK-derived KEK to wrap the SAK, identical to the PSK-mode path. No new SAK distribution logic is required. The `mode` field is set to `PSK` when creating a group CAK participant, ensuring the correct key derivation path is followed.

## 4. Timer Management Verification

Per ADR-MKA-001 (#36), timer constants are unchanged between 802.1X-2010 and 802.1X-2020. The following values are verified against Clause 9 normative requirements:

| Constant | Value (ms) | Clause Reference | Status |
|----------|-----------|------------------|--------|
| `MKA_HELLO_TIME` | 2000 | Clause 9 | Unchanged, verified |
| `MKA_BOUNDED_HELLO_TIME` | 500 | Clause 9 | Unchanged, verified |
| `MKA_LIFE_TIME` | 6000 | Clause 9 | Unchanged, verified |
| `MKA_SAK_RETIRE_TIME` | 3000 | Clause 9 | Unchanged, verified |

No new timer constants are required for the 2020 update. The suspension feature pauses existing timers without introducing new ones.

## 5. No Changes to ieee802_1x_kay_ctx

Per ADR-MKA-001 (#36), the `ieee802_1x_kay_ctx` struct (the driver callback interface) is intentionally left unchanged. This preserves binary compatibility with all existing MACsec driver implementations (`macsec_linux`, `macsec_qca`).

All new 802.1X-2020 MKA features operate at the protocol level (above the driver interface). Suspension/resume are handled internally within `ieee802_1x_kay.c`. Group CAK is handled during participant creation.

## 6. Build Integration

```makefile
# Existing (unchanged)
ifdef CONFIG_MACSEC
OBJS += ../src/pae/ieee802_1x_kay.o
OBJS += ../src/pae/ieee802_1x_key.o
endif

# 802.1X-2020 additions inside ieee802_1x_kay.c:
#   #ifdef CONFIG_IEEE8021X_2020
#     ... ieee802_1x_kay_suspend(), ieee802_1x_kay_resume()
#     ... ieee802_1x_kay_create_mka_2020()
#     ... suspension guard in kay_run_state_machine()
#     ... group CAK fields in participant
#   #endif
#
# No new object files. No new Makefile entries.
# CONFIG_IEEE8021X_2020 is implied by CONFIG_IEEE8021X_2020_LOGON.
```

## 7. Key Server Election (No Change)

The existing key server election algorithm in `ieee802_1x_kay.c` compares priority values and SCI to elect the key server among participants. IEEE 802.1X-2020 does not modify this algorithm. The existing implementation is verified correct for 2020 compliance. No code changes are required for REQ-F-MKA-002 (#14).

## 8. Logon Process Interface

The Logon Process (DESIGN-LOGON-001) interacts with KaY through the `ieee802_1x_logon_ctx` function pointers, not directly. The `wpas_logon.c` bridge wires these callbacks to the concrete KaY functions:

| Logon Process Callback | Concrete KaY Function |
|------------------------|----------------------|
| `ctx->kay_create_mka` | `ieee802_1x_kay_create_mka_2020()` (or `_compat`) |
| `ctx->kay_delete_mka` | `ieee802_1x_kay_delete_mka()` |

When the Logon Process receives `auth_success` and `nid_requires_mka == true`, it calls `kay_create_mka` which triggers MKA participant creation. When the MKA participant becomes operational (peers discovered, SAK distributed if Key Server), the wpas_logon bridge calls `ieee802_1x_logon_secured()` to signal the Logon Process.

## 9. Traceability

| Design Element | Implements | Governed By |
|----------------|-----------|-------------|
| `ieee802_1x_kay_suspend()`/`ieee802_1x_kay_resume()` | #17 REQ-F-MKA-005 (MKA suspension -- 2020 new) | #36 ADR-MKA-001 |
| `suspended` field in `ieee802_1x_mka_participant` | #17 REQ-F-MKA-005 | #36 ADR-MKA-001 |
| `ieee802_1x_kay_create_mka_2020()` with rp_key | #15 REQ-F-MKA-003 (group CAK per Clause 9.3.3) | #36 ADR-MKA-001 |
| `is_group_cak` and `rp_key` fields in participant | #15 REQ-F-MKA-003 | #36 ADR-MKA-001 |
| Timer constants verification (Section 4) | #16 REQ-F-MKA-004 (MKA timer management) | #36 ADR-MKA-001 |
| No `ieee802_1x_kay_ctx` changes (Section 5) | Backward compatibility (StR-008) | #36 ADR-MKA-001 |
| `CONFIG_IEEE8021X_2020` guards | #4 StR-008, #24 REQ-NF-COMPAT-001 | #33 ADR-COMPAT-001 |
| Key server election (unchanged) | #14 REQ-F-MKA-002 (Key Server election) | #36 ADR-MKA-001 |
| MKA participant state machine (extended, not rewritten) | #13 REQ-F-MKA-001 | #36 ADR-MKA-001 |

| GitHub Issue | Requirement | Design Coverage |
|-------------|-------------|-----------------|
| #13 | REQ-F-MKA-001: MKA participant state machine | Extended with suspension; core SM unchanged |
| #14 | REQ-F-MKA-002: Key Server election | No change required; existing implementation verified |
| #15 | REQ-F-MKA-003: SAK derivation and distribution | Group CAK path added; existing SAK path unchanged |
| #16 | REQ-F-MKA-004: MKA timer management | Timer values verified unchanged; suspend/resume pause timers |
| #17 | REQ-F-MKA-005: MKA suspension (2020 new) | Full: suspend/resume functions, participant flag, SM integration |
| #18 | REQ-NF-MKA-001: Hello Time <= 2000 ms | Timer values verified; unchanged from 2010 baseline |
| #2 | StR-002: MKA per Clause 9 | Covered by REQ-F-MKA-001 through 005 |
| #36 | ADR-MKA-001: Incremental KaY update | Governed: no SecY interface changes, in-place additions |
| #35 | ADR-PAE-002: Function-pointer DI | Governed: kay_ctx unchanged; new functions use existing pattern |
| #33 | ADR-COMPAT-001: Compile-time feature gating | Governed: all new code under CONFIG_IEEE8021X_2020 |
