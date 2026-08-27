# DESIGN-PAE-001: Supplicant PACP Update Design

| Field | Value |
|-------|-------|
| Status | Draft |
| Date | 2026-05-16 |
| Implements | REQ-F-PAE-001 (#5), REQ-F-PAE-002 (#6), REQ-F-PAE-003 (#7), REQ-F-PAE-004 (#8), REQ-F-PAE-005 (#9) |
| Governed By | ADR-PAE-001 (#34), ADR-PAE-002 (#35), ADR-COMPAT-001 (#33), ADR-ARCH-001 (#32) |

## 1. Overview

This document specifies the design for updating the Supplicant Port Access Control Protocol (PACP) state machine in `src/eapol_supp/eapol_supp_sm.c` to comply with IEEE 802.1X-2020 Clause 8. Per ADR-PAE-001 (#34), all changes are incremental in-place additions to the existing `eapol_sm` struct and functions, guarded by `#ifdef CONFIG_IEEE8021X_2020`. No new source files are created.

The 802.1X-2020 changes to the Supplicant PACP are:
1. **New state variables** for Clause 8.3 conformance
2. **Logon Process callback interface** for Clause 12 integration
3. **Variable aliasing** for PACP/PAE naming alignment
4. **Timer and heldPeriod adjustments** per Clause 8 updates

## 2. Current Baseline

The existing `eapol_sm` struct (in `src/eapol_supp/eapol_supp_sm.c`) contains the Supplicant PAE, Key Receive, and Supplicant Backend state machines as defined by IEEE 802.1X-2004/2010. Key existing variables:

| Variable | Type | Purpose |
|----------|------|---------|
| `authWhile` | `unsigned int` | Timer: counts down from `authPeriod` |
| `heldWhile` | `unsigned int` | Timer: counts down from `heldPeriod` |
| `startWhen` | `unsigned int` | Timer: counts down from `startPeriod` |
| `idleWhile` | `unsigned int` | Timer: EAP state machine idle timer |
| `eapFail` | `bool` | EAP failure flag |
| `eapolEap` | `bool` | EAPOL-EAP frame received |
| `eapSuccess` | `bool` | EAP success flag |
| `portEnabled` | `bool` | Physical port operational status |
| `portValid` | `bool` | Port validation status |
| `suppPortStatus` | `PortStatus` | Controlled port status (Authorized/Unauthorized) |
| `userLogoff` | `bool` | User-initiated logoff flag |
| `logoffSent` | `bool` | EAPOL-Logoff sent flag |
| `startCount` | `unsigned int` | Number of EAPOL-Start frames sent |
| `heldPeriod` | `unsigned int` | HELD state duration (default 60 s) |
| `startPeriod` | `unsigned int` | Start retransmit period (default 30 s) |
| `maxStart` | `unsigned int` | Max EAPOL-Start retransmits (default 3) |
| `authPeriod` | `unsigned int` | Auth timeout period (default 30 s) |

## 3. New State Variables (Clause 8.3)

### 3.1 Variables to Add

The following variables are added inside the `eapol_sm` struct, guarded by `#ifdef CONFIG_IEEE8021X_2020`:

```c
/* Inside struct eapol_sm (eapol_supp_sm.c) */

#ifdef CONFIG_IEEE8021X_2020
    /* ---- 802.1X-2020 Clause 8 additions ---- */

    /* NID association flag: true when this PACP session is bound to a NID
     * via the Logon Process (Clause 12). */
    bool pacp_nid_associated;

    /* EAPOL-Start variant for NID-aware authentication.
     * When true, EAPOL-Start includes the NID in the EAPOL frame
     * per Clause 8.3 update. */
    bool eapStart_nid;

    /* Reauthentication trigger from Logon Process.
     * Set by logon_if->logon_connect(); cleared by sm_step. */
    bool reAuthenticate;

    /* Authentication outcome signalled to Logon Process.
     * These are output signals consumed by the Logon Process
     * through the ieee802_1x_pacp_logon_if callbacks. */
    bool auth_notify_success;    /* True when PACP authentication succeeds */
    bool auth_notify_failure;    /* True when PACP authentication fails */

    /* Logon Process callback interface */
    struct ieee802_1x_pacp_logon_if *logon_if;
#endif /* CONFIG_IEEE8021X_2020 */
```

### 3.2 Variable Descriptions

| Variable | Type | Purpose | Clause Reference |
|----------|------|---------|------------------|
| `pacp_nid_associated` | `bool` | Indicates this PACP session is bound to a NID | Clause 8.3 |
| `eapStart_nid` | `bool` | EAPOL-Start includes NID variant | Clause 8.3 |
| `reAuthenticate` | `bool` | Reauthentication trigger from Logon Process | Clause 8.3 |
| `auth_notify_success` | `bool` | Output: authentication success to Logon Process | Clause 8.3 |
| `auth_notify_failure` | `bool` | Output: authentication failure to Logon Process | Clause 8.3 |
| `logon_if` | `struct ieee802_1x_pacp_logon_if *` | Logon Process callback interface | Clause 12 |

## 4. Variable Aliasing

IEEE 802.1X-2020 renames some variables from the 2010 edition. Per ADR-PAE-001 (#34), the existing variable names are preserved, and new names are exposed as macro aliases. This avoids breaking any existing callers while providing the 2020-named accessors.

### 4.1 Alias Definitions

```c
/* In eapol_supp_sm.h, guarded by CONFIG_IEEE8021X_2020 */

#ifdef CONFIG_IEEE8021X_2020
/*
 * Variable aliases: 802.1X-2020 PACP naming conventions.
 * The original 2010 variable names remain the primary storage.
 * These macros allow 2020-aware code to use the PACP names.
 *
 * Per ADR-PAE-001 (#34): alias rather than rename.
 */

/* Timer variable aliases (2020 names -> 2010 storage) */
#define authWhileCounter     authWhile      /* Clause 8: authWhile counter */
#define heldWhileCounter     heldWhile      /* Clause 8: heldWhile counter */
#define startWhenCounter     startWhen      /* Clause 8: startWhen counter */

/* State aliases */
#define SUPP_PACP_DISCONNECTED   SUPP_PAE_DISCONNECTED
#define SUPP_PACP_CONNECTING     SUPP_PAE_CONNECTING
#define SUPP_PACP_AUTHENTICATING SUPP_PAE_AUTHENTICATING
#define SUPP_PACP_AUTHENTICATED  SUPP_PAE_AUTHENTICATED
#define SUPP_PACP_HELD           SUPP_PAE_HELD
#define SUPP_PACP_RESTART        SUPP_PAE_RESTART

/* Port status alias */
#define pacpPortStatus  suppPortStatus

#endif /* CONFIG_IEEE8021X_2020 */
```

### 4.2 Rationale for Aliasing

Aliasing preserves full backward compatibility:
- All existing code that uses `SUPP_PAE_DISCONNECTED` continues to work.
- New 802.1X-2020 code can use `SUPP_PACP_DISCONNECTED` for clarity.
- No `#ifdef` is needed at call sites; the alias is a compile-time substitution.

## 5. Logon Process Callback Interface

### 5.1 Interface Struct

The `ieee802_1x_pacp_logon_if` struct provides the mechanism for the Logon Process (Clause 12) to initiate and terminate PACP authentication without bypassing the Supplicant PAE state machine. Per ADR-PAE-002 (#35), this uses function-pointer injection.

```c
/**
 * struct ieee802_1x_pacp_logon_if - Logon Process callback interface for PACP
 *
 * Allows the Logon Process (ARC-C-LOGON-001) to connect/disconnect
 * the PACP session. The PACP signals authentication outcomes back
 * to the Logon Process through these callbacks.
 *
 * Per ADR-PAE-002 (#35) -- function-pointer DI pattern.
 * Guarded by #ifdef CONFIG_IEEE8021X_2020.
 */
#ifdef CONFIG_IEEE8021X_2020
struct ieee802_1x_pacp_logon_if {
    /** Opaque context pointer passed back to all callbacks */
    void *ctx;

    /** Logon Process -> PACP: initiate authentication for the selected NID */
    void (*logon_connect)(void *ctx);

    /** Logon Process -> PACP: terminate current authentication */
    void (*logon_disconnect)(void *ctx);

    /** PACP -> Logon Process: authentication succeeded */
    void (*auth_success)(void *ctx);

    /** PACP -> Logon Process: authentication failed */
    void (*auth_failure)(void *ctx);
};
#endif /* CONFIG_IEEE8021X_2020 */
```

### 5.2 Registration Function

```c
/**
 * eapol_sm_set_logon_if - Register Logon Process callback interface
 * @sm: EAPOL supplicant state machine pointer.
 * @logon_if: Pointer to Logon Process callback struct (copied internally).
 *
 * Stores the callback interface for use by the PACP state machine.
 * Must be called before eapol_sm_step() for the interface to take effect.
 * Passing NULL deregisters the interface.
 *
 * Guarded by #ifdef CONFIG_IEEE8021X_2020.
 *
 * @implements #9 REQ-F-PAE-005
 * @governed #35 ADR-PAE-002
 */
#ifdef CONFIG_IEEE8021X_2020
void eapol_sm_set_logon_if(struct eapol_sm *sm,
                            const struct ieee802_1x_pacp_logon_if *logon_if);
#endif /* CONFIG_IEEE8021X_2020 */
```

### 5.3 Callback Invocation Points

The PACP state machine invokes Logon Process callbacks at the following points within `eapol_sm_step()`:

| Callback | Invoked When | Location in eapol_supp_sm.c |
|----------|-------------|---------------------------|
| `logon_if->auth_success` | SUPP_PAE enters AUTHENTICATED state and `logon_if` is registered | Supplicant PAE SM step |
| `logon_if->auth_failure` | SUPP_PAE enters HELD state or SUPP_BE enters FAIL/TIMEOUT state and `logon_if` is registered | Supplicant PAE SM step, Supplicant Backend SM step |
| `logon_if->logon_connect` | Not called by PACP; this is a Logon Process -> PACP direction | N/A (Logon Process calls this on the PACP) |
| `logon_if->logon_disconnect` | Not called by PACP; this is a Logon Process -> PACP direction | N/A |

When `logon_if` is NULL (not registered), the PACP operates exactly as it did before the 2020 update, maintaining backward compatibility.

### 5.4 Integration with eapol_sm_notify_portEnabled

The existing `eapol_sm_notify_portEnabled()` function is the primary entry point for port status changes. When the Logon Process calls `logon_connect()`, the concrete implementation in `wpas_logon.c` will call `eapol_sm_notify_portEnabled(sm, true)`. This ensures the PACP state machine follows its normal initialization path without special casing.

```c
/* In wpas_logon.c (bridge): concrete implementation of logon_connect */
static void wpas_logon_connect(void *ctx)
{
    struct wpa_supplicant *wpa_s = ctx;
    if (wpa_s->eapol)
        eapol_sm_notify_portEnabled(wpa_s->eapol, true);
}
```

## 6. authWhileCounter Reset on Logon Connect

### 6.1 Current Behavior

In the existing implementation, `authWhile` is reset in the Supplicant PAE state machine when entering the CONNECTING state (from DISCONNECTED or RESTART). This happens as a side effect of `eapol_sm_notify_portEnabled(sm, true)`.

### 6.2 2020 Addition

Per Clause 8.3, when the Logon Process signals `logon_connect()` to initiate reauthentication, the `authWhile` counter must also be reset, even if the port was already enabled. This ensures a fresh authentication attempt timing.

```c
/* Inside eapol_sm_set_logon_if() implementation or a helper called from
 * the logon_connect concrete implementation in wpas_logon.c */

#ifdef CONFIG_IEEE8021X_2020
static void pacp_reset_auth_timer(struct eapol_sm *sm)
{
    if (!sm)
        return;
    sm->authWhile = sm->authPeriod;
    sm->startCount = 0;  /* Reset start count for new attempt */
}
#endif
```

This is called from the `wpas_logon_connect()` bridge function after calling `eapol_sm_notify_portEnabled()`.

## 7. heldPeriod and quietWhile Timer Verification

### 7.1 Timer Constants

| Constant | Default | 2010 Value | 2020 Value | Change |
|----------|---------|------------|------------|--------|
| `heldPeriod` | 60 s | 60 s | 60 s | None |
| `startPeriod` | 30 s | 30 s | 30 s | None |
| `maxStart` | 3 | 3 | 3 | None |
| `authPeriod` | 30 s | 30 s | 30 s | None |

IEEE 802.1X-2020 does not change the normative timer values for the Supplicant PACP. The existing timer tick implementation (`eapol_port_timers_tick()`) is sufficient.

### 7.2 quietWhile Timer

The 2020 standard introduces the concept of `quietWhile` as a separate variable from `heldWhile` for some PACP scenarios. In the Supplicant role, `heldWhile` already serves this purpose (the HELD state duration). No additional timer variable is required for the Supplicant PACP. The Authenticator PACP (not in Wave 1 scope) may require the separation.

## 8. portStatus Reporting

### 8.1 Current Behavior

The existing `eapol_sm` reports port status through the `suppPortStatus` variable and the `eapol_ctx->port_cb` callback. When the port becomes authorized, `eapol_sm_set_port_authorized()` is called; when unauthorized, `eapol_sm_set_port_unauthorized()`.

### 8.2 2020 Addition

When the Logon Process interface is registered (`logon_if != NULL`), the PACP must also signal authentication outcome through the `logon_if->auth_success` / `logon_if->auth_failure` callbacks. This is in addition to (not replacing) the existing `port_cb` notification.

```c
/* In eapol_sm_set_port_authorized() -- guarded addition */
#ifdef CONFIG_IEEE8021X_2020
    if (sm->logon_if && sm->logon_if->auth_success)
        sm->logon_if->auth_success(sm->logon_if->ctx);
#endif
```

```c
/* In eapol_sm_set_port_unauthorized() -- guarded addition */
#ifdef CONFIG_IEEE8021X_2020
    if (sm->logon_if && sm->logon_if->auth_failure)
        sm->logon_if->auth_failure(sm->logon_if->ctx);
#endif
```

### 8.3 Callback Deduplication

The `logon_if->auth_success` and `logon_if->auth_failure` callbacks should only be invoked once per authentication attempt. The `auth_notify_success` and `auth_notify_failure` flags track whether the notification has been sent. They are cleared when a new authentication attempt begins (entry to CONNECTING state or `logon_connect()` signal).

```c
/* Clear notification flags on new auth attempt */
#ifdef CONFIG_IEEE8021X_2020
    sm->auth_notify_success = false;
    sm->auth_notify_failure = false;
#endif
```

## 9. Reauthentication via Logon Process

### 9.1 Mechanism

When the Logon Process calls `logon_connect()` for reauthentication, the PACP must:
1. Reset `authWhile` to `authPeriod`
2. Reset `startCount` to 0
3. Set `eapRestart = true` to restart the EAP state machine
4. Transition to RESTART state in the Supplicant PAE SM

The existing `eapol_sm_request_reauth()` function provides this functionality and is called from the bridge:

```c
/* In wpas_logon.c (bridge): reauthentication concrete implementation */
static void wpas_logon_reauth(void *ctx)
{
    struct wpa_supplicant *wpa_s = ctx;
    if (wpa_s->eapol)
        eapol_sm_request_reauth(wpa_s->eapol);
}
```

### 9.2 reAuthenticate Variable

The `reAuthenticate` variable in the extended `eapol_sm` struct is set by the Logon Process through the `logon_connect` callback. The Supplicant PAE state machine evaluates this variable in the AUTHENTICATED state: when `reAuthenticate == true`, it transitions to RESTART.

```c
/* Inside Supplicant PAE state machine step (AUTHENTICATED state) */
#ifdef CONFIG_IEEE8021X_2020
    if (sm->reAuthenticate) {
        sm->reAuthenticate = false;
        /* Transition to RESTART state */
        SM_ENTER(SUPP_PAE, RESTART);
    }
#endif
```

## 10. Build Integration

```makefile
# Enabled when CONFIG_IEEE8021X_EAPOL=y (existing, unchanged)
OBJS += ../src/eapol_supp/eapol_supp_sm.o

# 802.1X-2020 variable extensions are inside:
# #ifdef CONFIG_IEEE8021X_2020
#   ... new Clause 8 variables, pacp_logon_if callbacks
# #endif
#
# No new object files. No new Makefile entries.
# CONFIG_IEEE8021X_2020 is implied by CONFIG_IEEE8021X_2020_LOGON.
```

## 11. Non-Functional Requirements

### 11.1 Performance (REQ-NF-PERF-001, #10)

The PACP changes add a small number of boolean checks in the state machine step function. When `logon_if` is NULL (not registered), the overhead is a single pointer comparison per step iteration. This is well within the 100 ms p95 EAPOL response requirement.

### 11.2 Backward Compatibility (REQ-NF-PAE-COMPAT-001, #12)

All additions are guarded by `#ifdef CONFIG_IEEE8021X_2020`. When the flag is not defined, the `eapol_sm` struct and all functions are byte-identical to the 2010 baseline. The variable aliases are also guarded, so they do not affect compilation when the flag is off.

Verification: a non-regression build with `CONFIG_IEEE8021X_2020` undefined must produce the same object file as the upstream baseline (wpa_supplicant 2.12 since the 2026-08-27 rebase).

## 12. Design Rationale

### 12.1 In-Place Extension vs. New File

Per ADR-PAE-001 (#34), the PACP update extends `eapol_supp_sm.c` in place rather than creating a new file. This avoids duplication of the complex state machine logic and ensures that 2020-specific changes are immediately adjacent to the code they modify, making review easier.

### 12.2 Function-Pointer DI for Logon Interface

Per ADR-PAE-002 (#35), the Logon Process interface uses function pointers rather than direct struct access. This allows:
- Unit testing the PACP with a mock Logon Process
- The Logon Process and PACP to be compiled independently
- Clean separation of concerns (PACP does not know about Logon Process internals)

### 12.3 Alias Strategy for Variable Renaming

The 2020 standard renames "PAE" to "PACP" in several contexts. Rather than globally renaming variables (which would break every caller), the alias approach allows gradual adoption: new code uses PACP names, old code continues using PAE names, and both resolve to the same storage.

## 13. Traceability

| Design Element | Implements | Governed By |
|----------------|-----------|-------------|
| New state variables (Section 3) | #6 REQ-F-PAE-002 (PACP variables 2020) | #34 ADR-PAE-001 |
| Variable aliasing (Section 4) | #6 REQ-F-PAE-002 (naming alignment) | #34 ADR-PAE-001 |
| `ieee802_1x_pacp_logon_if` struct (Section 5) | #9 REQ-F-PAE-005 (Logon Process interface) | #35 ADR-PAE-002 |
| `eapol_sm_set_logon_if()` (Section 5.2) | #9 REQ-F-PAE-005 | #35 ADR-PAE-002 |
| authWhileCounter reset on logon_connect (Section 6) | #7 REQ-F-PAE-003 (timer management) | #34 ADR-PAE-001 |
| Timer constants verification (Section 7) | #7 REQ-F-PAE-003 (heldPeriod, quietWhile) | #34 ADR-PAE-001 |
| portStatus reporting with logon_if (Section 8) | #8 REQ-F-PAE-004 (portStatus reporting) | #34 ADR-PAE-001 |
| reAuthenticate variable (Section 9) | #5 REQ-F-PAE-001 (reauth path per Clause 8) | #34 ADR-PAE-001 |
| `CONFIG_IEEE8021X_2020` guards | #12 REQ-NF-PAE-COMPAT-001 (zero change when disabled) | #33 ADR-COMPAT-001 |
| Performance analysis (Section 11.1) | #10 REQ-NF-PERF-001 (EAPOL response <100 ms p95) | #34 ADR-PAE-001 |

| GitHub Issue | Requirement | Design Coverage |
|-------------|-------------|-----------------|
| #5 | REQ-F-PAE-001: Supplicant PAE state machine Clause 8.3 | Full (reAuthenticate variable, RESTART transition) |
| #6 | REQ-F-PAE-002: PACP variables 2020 | Full (new variables, aliases) |
| #7 | REQ-F-PAE-003: heldPeriod, quietWhile timers | Full (timer verification, authWhile reset) |
| #8 | REQ-F-PAE-004: portStatus reporting | Full (logon_if notification in addition to port_cb) |
| #9 | REQ-F-PAE-005: Logon Process interface | Full (ieee802_1x_pacp_logon_if, eapol_sm_set_logon_if) |
| #10 | REQ-NF-PERF-001: EAPOL response <100 ms p95 | Verified (minimal overhead from boolean checks) |
| #12 | REQ-NF-PAE-COMPAT-001: Zero change when flag disabled | Full (all additions guarded) |
| #34 | ADR-PAE-001: Incremental PACP update strategy | Governed |
| #35 | ADR-PAE-002: Function-pointer DI pattern | Governed |
| #33 | ADR-COMPAT-001: Compile-time feature gating | Governed |
