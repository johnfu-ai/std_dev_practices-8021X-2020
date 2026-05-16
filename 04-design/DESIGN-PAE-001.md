# DESIGN-PAE-001: Supplicant PACP State Machine Update Design

| Field | Value |
|---|---|
| **Status** | Draft |
| **Date** | 2026-05-16 |
| **Implements** | #5-#9 (REQ-F-PAE-001..005) |
| **Governed By** | #34 (ADR-PAE-001), #35 (ADR-PAE-002), #33 (ADR-COMPAT-001) |
| **Component** | ARC-C-PACP-001 (#40) |

---

## Design Approach

Per ADR-PAE-001 (#34), the Supplicant PACP is updated **incrementally in-place** within `src/eapol_supp/eapol_supp_sm.c`. No new files are created. All 802.1X-2020 additions are guarded by `#ifdef CONFIG_IEEE8021X_2020`.

---

## State Machine Variable Changes

### New Variables (guarded by `#ifdef CONFIG_IEEE8021X_2020`)

| 802.1X-2020 Name | Existing Name | Action | Guard |
|---|---|---|---|
| `PACP_NID` | — | Add `u8 *pacp_nid; size_t pacp_nid_len;` to `struct eapol_sm` | `CONFIG_IEEE8021X_2020` |
| `logon_if` | — | Add `struct ieee802_1x_pacp_logon_if *logon_if;` to `struct eapol_sm` | `CONFIG_IEEE8021X_2020` |

### Variable Aliases (macro-based, no behavioral change)

```c
#ifdef CONFIG_IEEE8021X_2020
/* Per ADR-PAE-001 (#34): alias 2020 names to existing variables */
#define pacpPortEnabled  portEnabled
#define pacpPortValid    portValid
#endif
```

---

## New Interface: Logon Process Callbacks

### Data Structure

```c
/*
 * ieee802_1x_pacp_logon_if - Logon Process → PACP callback interface
 * Per ADR-PAE-002 (#35): function-pointer DI for inter-SM interfaces
 * See: IEEE 802.1X-2020, Clause 12
 */
struct ieee802_1x_pacp_logon_if {
    void (*logon_connect)(void *ctx);
    void (*logon_disconnect)(void *ctx);
    void *ctx;
};
```

### API Function

```c
#ifdef CONFIG_IEEE8021X_2020
/**
 * eapol_sm_set_logon_if - Register Logon Process callbacks
 * @sm: Supplicant PACP state machine
 * @logon_if: Callback interface from Logon Process
 *
 * Per ADR-PAE-002 (#35): DI registration for Logon→PACP interface.
 *
 * @implements #9 REQ-F-PAE-005: Logon Process client interface per Clause 8.4
 */
void eapol_sm_set_logon_if(struct eapol_sm *sm,
                            const struct ieee802_1x_pacp_logon_if *logon_if);
#endif
```

### Integration Points

When `logon_if->logon_connect()` is called:
1. Reset `authWhileCounter` to 0
2. Trigger EAPOL-Start transmission (equivalent to `eapol_sm_notify_portEnabled(sm, true)`)
3. Transition to CONNECTING state if currently DISCONNECTED

When `logon_if->logon_disconnect()` is called:
1. Abort in-progress EAP exchange
2. Transition to DISCONNECTED state
3. Clear `eapSuccess` and `eapFail` flags

---

## authWhileCounter Reset Behavior

Per Clause 8, `authWhileCounter` counts down during HELD state. In 802.1X-2020, the Logon Process can reset this counter via `logon_connect()`, forcing an immediate re-authentication attempt.

```c
#ifdef CONFIG_IEEE8021X_2020
static void eapol_sm_logon_connect_cb(void *ctx)
{
    struct eapol_sm *sm = ctx;
    if (!sm)
        return;
    sm->authWhile = 0;  /* Force immediate re-attempt */
    eapol_sm_step(sm);   /* Re-evaluate state machine */
}
#endif
```

---

## State Transition Modifications

### Existing States (unchanged behavior when flag disabled)

| State | 802.1X-2020 Change | Guard |
|---|---|---|
| DISCONNECTED | No change | — |
| CONNECTING | No change | — |
| AUTHENTICATING | No change | — |
| AUTHENTICATED | No change | — |
| HELD | `authWhileCounter` can be reset by Logon Process | `CONFIG_IEEE8021X_2020` |
| RESTART | No change | — |

---

## Build Integration

```makefile
# Existing — no new object files
OBJS += ../src/eapol_supp/eapol_supp_sm.o

# 802.1X-2020 additions are inline within eapol_supp_sm.c:
# #ifdef CONFIG_IEEE8021X_2020
#   ... struct additions, logon_if, pacp_nid
# #endif
```

---

## Traceability

| Requirement | Design Element | Status |
|---|---|---|
| #5 REQ-F-PAE-001 (State machine) | No state changes, variable aliases only | Designed |
| #6 REQ-F-PAE-002 (Logon interface) | `ieee802_1x_pacp_logon_if`, `eapol_sm_set_logon_if()` | Designed |
| #7 REQ-F-PAE-003 (EAPOL Tx/Rx) | logon_connect triggers EAPOL-Start | Designed |
| #8 REQ-F-PAE-004 (Timers/counters) | authWhileCounter reset via logon_connect | Designed |
| #9 REQ-F-PAE-005 (EAP methods/CAK) | Deferred to Wave 2 (EAP-TEAP) | Deferred |
| #10 REQ-NF-PERF-001 (Timing) | No path lengthening when flag disabled | Verified by design |
| #12 REQ-NF-PAE-COMPAT-001 (Compat) | All changes guarded, zero impact when off | Verified by design |
