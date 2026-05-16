# DESIGN-LOGON-001: Logon Process State Machine Design

| Field | Value |
|-------|-------|
| Status | Draft |
| Date | 2026-05-16 |
| Implements | REQ-F-LOGON-001 (#19), REQ-F-LOGON-002 (#20), REQ-F-LOGON-003 (#21), REQ-F-LOGON-004 (#22) |
| Governed By | ADR-LOGON-001 (#37), ADR-PAE-002 (#35), ADR-COMPAT-001 (#33), ADR-ARCH-001 (#32) |

## 1. Overview

This document specifies the detailed design for the IEEE 802.1X-2020 Clause 12 Logon Process state machine. The Logon Process is the primary new component in Wave 1. It orchestrates NID-aware network selection, initiates PACP authentication, interprets the authentication outcome, and signals the Controlled Port to connect at the appropriate security level.

The current implementation in `src/pae/ieee802_1x_logon.c` provides init/deinit, port_enabled, auth_success, auth_failure, secured, and sm_step with 24 passing tests. The existing implementation uses direct state mutation in event functions. This document specifies the migration to a pending-flag pattern and the addition of reauth_request, suspend, NID management, and timer support.

## 2. State Transition Table

The Logon Process state machine has 5 states and 6 external events. Transitions are evaluated in `ieee802_1x_logon_sm_step()`, which processes pending event flags set by event functions.

### 2.1 States

| State Enum | Name | Description |
|------------|------|-------------|
| `LOGON_DISCONNECTED` | DISCONNECTED | Port is down or no active session; initial state |
| `LOGON_LOGON` | LOGON | Port enabled; selecting NID and initiating PACP |
| `LOGON_AUTHENTICATING` | AUTHENTICATING | PACP authentication succeeded; MKA establishment in progress |
| `LOGON_AUTHENTICATED` | AUTHENTICATED | PACP succeeded and no MKA required, or MKA suspended; CP signalled connect_authenticated |
| `LOGON_SECURED` | SECURED | MKA session active; CP signalled connect_secure |

### 2.2 Events

| Event | Trigger Function | Description |
|-------|-------------------|-------------|
| port_enabled | `ieee802_1x_logon_port_enabled(logon, true)` | Physical port operationally up |
| port_disabled | `ieee802_1x_logon_port_enabled(logon, false)` | Physical port operationally down |
| auth_success | `ieee802_1x_logon_auth_success(logon)` | PACP reports authentication succeeded |
| auth_failure | `ieee802_1x_logon_auth_failure(logon)` | PACP reports authentication failed |
| secured | `ieee802_1x_logon_secured(logon)` | MKA session establishment complete |
| reauth_request | `ieee802_1x_logon_reauth_request(logon)` | Reauthentication timer expiry or external trigger |

### 2.3 Full Transition Table

| # | Current State | Event | Guard | Action | Next State |
|---|---------------|-------|-------|--------|------------|
| T1 | DISCONNECTED | port_enabled | (none) | `logon_connect(ctx->ctx)`; signal CP `connect_pending`; start connect_timeout timer | LOGON |
| T2 | DISCONNECTED | port_disabled | (none) | (no-op) | DISCONNECTED |
| T3 | DISCONNECTED | auth_success | (none) | (no-op -- ignore spurious) | DISCONNECTED |
| T4 | DISCONNECTED | auth_failure | (none) | (no-op -- ignore spurious) | DISCONNECTED |
| T5 | DISCONNECTED | reauth_request | (none) | (no-op) | DISCONNECTED |
| T6 | DISCONNECTED | secured | (none) | (no-op) | DISCONNECTED |
| T7 | LOGON | port_disabled | (none) | `logon_disconnect(ctx->ctx)`; `kay_delete_mka` if active participant; stop connect_timeout; signal CP `connect_unauthenticated` | DISCONNECTED |
| T8 | LOGON | auth_success | `nid_requires_mka == true` | Signal CP `connect_authenticated`; call `kay_create_mka` with NID CKN/CAK; start mka_wait timer | AUTHENTICATING |
| T9 | LOGON | auth_success | `nid_requires_mka == false` | Signal CP `connect_authenticated`; stop connect_timeout; start reauth timer | AUTHENTICATED |
| T10 | LOGON | auth_failure | (none) | `logon_disconnect(ctx->ctx)`; signal CP `connect_unauthenticated`; stop connect_timeout | DISCONNECTED |
| T11 | LOGON | reauth_request | (none) | (no-op -- already in LOGON) | LOGON |
| T12 | LOGON | secured | (none) | (no-op -- cannot be secured before auth) | LOGON |
| T13 | LOGON | port_enabled | (none) | (no-op -- already in LOGON) | LOGON |
| T14 | AUTHENTICATING | secured | (none) | Signal CP `connect_secure`; stop mka_wait timer; start reauth timer | SECURED |
| T15 | AUTHENTICATING | auth_failure | (none) | `logon_disconnect(ctx->ctx)`; `kay_delete_mka` if participant; signal CP `connect_unauthenticated`; stop mka_wait timer | DISCONNECTED |
| T16 | AUTHENTICATING | port_disabled | (none) | `logon_disconnect(ctx->ctx)`; `kay_delete_mka` if participant; signal CP `connect_unauthenticated`; stop mka_wait timer | DISCONNECTED |
| T17 | AUTHENTICATING | auth_success | (none) | (no-op -- already processing auth) | AUTHENTICATING |
| T18 | AUTHENTICATING | reauth_request | (none) | (no-op -- authentication in progress) | AUTHENTICATING |
| T19 | AUTHENTICATED | reauth_request | (none) | `logon_connect(ctx->ctx)`; signal CP `connect_pending`; stop reauth timer; start connect_timeout timer | LOGON |
| T20 | AUTHENTICATED | port_disabled | (none) | `logon_disconnect(ctx->ctx)`; signal CP `connect_unauthenticated`; stop reauth timer | DISCONNECTED |
| T21 | AUTHENTICATED | secured | (none) | Signal CP `connect_secure`; stop reauth timer; start reauth timer | SECURED |
| T22 | AUTHENTICATED | auth_success | (none) | (no-op -- already authenticated) | AUTHENTICATED |
| T23 | AUTHENTICATED | auth_failure | (none) | Signal CP `connect_unauthenticated`; stop reauth timer | DISCONNECTED |
| T24 | SECURED | reauth_request | (none) | `logon_connect(ctx->ctx)`; signal CP `connect_pending`; stop reauth timer; start connect_timeout timer | LOGON |
| T25 | SECURED | port_disabled | (none) | `logon_disconnect(ctx->ctx)`; `kay_delete_mka`; signal CP `connect_unauthenticated`; stop reauth timer | DISCONNECTED |
| T26 | SECURED | auth_failure | (none) | `logon_disconnect(ctx->ctx)`; `kay_delete_mka`; signal CP `connect_unauthenticated`; stop reauth timer | DISCONNECTED |
| T27 | SECURED | auth_success | (none) | (no-op -- already secured) | SECURED |
| T28 | SECURED | secured | (none) | (no-op -- already secured) | SECURED |

### 2.4 Internal Guard Conditions

| Guard | Type | Description |
|-------|------|-------------|
| `nid_requires_mka` | `bool` | True when the selected NID's security policy requires MACsec (Clause 12 NID policy) |

### 2.5 Timer Specification

| Timer | Default | Purpose | Reset Condition |
|-------|---------|---------|-----------------|
| `connect_timeout` | 30 s | Maximum time in LOGON state awaiting auth result | Started on T1; cancelled on T7, T9, T10 |
| `reauth_period` | 3600 s | Period between reauthentications in AUTHENTICATED/SECURED | Started on T9, T14, T21; cancelled on T19, T20, T23, T24, T25, T26 |
| `mka_wait_timeout` | 6 s | Maximum time in AUTHENTICATING awaiting MKA establishment | Started on T8; cancelled on T14, T15, T16 |

Timer expiry fires through the `eloop` event mechanism and sets the corresponding pending event flag, which is then processed by the next `sm_step` call. The `connect_timeout` and `mka_wait_timeout` expiries are treated as `auth_failure` events. The `reauth_period` expiry is treated as a `reauth_request` event.

## 3. C Struct Layout

### 3.1 Extended `ieee802_1x_logon` Struct

```c
/**
 * struct ieee802_1x_logon - Logon Process state machine (opaque to callers)
 *
 * Per IEEE 802.1X-2020 Clause 12. All fields are private; callers use
 * the accessor functions declared in ieee802_1x_logon.h.
 *
 * Extended from initial skeleton: adds NID fields, reauth timer,
 * MKA wait timer, connect timeout, and pending event flags.
 */
struct ieee802_1x_logon {
    /* ---- Core fields (existing) ---- */
    struct ieee802_1x_logon_ctx *ctx;
    enum ieee802_1x_logon_state state;
    bool port_enabled;

    /* ---- NID fields (Wave 1: single NID) ---- */
    u8 nid[IEEE802_1X_MAX_NID_LEN];    /* Current Network Identity */
    size_t nid_len;                     /* Length of NID in bytes */
    bool nid_set;                       /* True if NID has been configured */
    bool nid_requires_mka;              /* NID policy: MACsec required */

    /* ---- Timer fields ---- */
    unsigned int connect_timeout;       /* Max seconds in LOGON (default 30) */
    unsigned int reauth_period;         /* Seconds between reauth (default 3600) */
    unsigned int mka_wait_timeout;      /* Max seconds in AUTHENTICATING (default 6) */
    bool connect_timeout_running;
    bool reauth_timer_running;
    bool mka_wait_timer_running;

    /* ---- MKA session tracking ---- */
    bool mka_participant_active;        /* True if participant created via kay_create_mka */
    struct mka_key_name active_ckn;     /* CKN of the active MKA session */
    struct mka_key active_cak;          /* CAK of the active MKA session */

    /* ---- Pending event flags (set by event functions, cleared by sm_step) ---- */
    bool pending_port_enabled;
    bool pending_port_disabled;
    bool pending_auth_success;
    bool pending_auth_failure;
    bool pending_secured;
    bool pending_reauth_request;
};
```

### 3.2 NID Maximum Length Constant

```c
#define IEEE802_1X_MAX_NID_LEN  32  /* Maximum NID length per Clause 12 */
```

### 3.3 Extended `ieee802_1x_logon_ctx` DI Struct

The existing `ieee802_1x_logon_ctx` in `ieee802_1x_logon.h` is extended with KaY interface callbacks. These were specified in ARC-C-LOGON-001 but are not yet in the header.

```c
struct ieee802_1x_logon_ctx {
    /** Caller-supplied opaque context pointer, passed back to all callbacks */
    void *ctx;

    /** Signal PACP to initiate authentication for the selected NID */
    void (*logon_connect)(void *ctx);

    /** Signal PACP to terminate authentication */
    void (*logon_disconnect)(void *ctx);

    /** Signal CP to set port connectivity to AUTHENTICATED */
    void (*cp_connect_authenticated)(void *ctx);

    /** Signal CP to set port connectivity to SECURE */
    void (*cp_connect_secure)(void *ctx);

    /** Signal CP to set port connectivity to PENDING */
    void (*cp_connect_pending)(void *ctx);

    /** Signal CP to set port connectivity to UNAUTHENTICATED */
    void (*cp_connect_unauthenticated)(void *ctx);

    /* ---- KaY interface (new) ---- */

    /** Create MKA participant for selected NID */
    int  (*kay_create_mka)(void *ctx, const struct mka_key_name *ckn,
                           const struct mka_key *cak, u32 life,
                           enum mka_created_mode mode);

    /** Delete MKA participant */
    void (*kay_delete_mka)(void *ctx, struct ieee802_1x_mka_sci *sci);
};
```

## 4. Function Signatures

### 4.1 Existing Functions (Preserved Contract)

The following functions already exist in `ieee802_1x_logon.h` and `ieee802_1x_logon.c`. Their public API remains unchanged; their implementations will be enhanced to use the pending-flag pattern.

```c
/**
 * ieee802_1x_logon_init - Initialize the Logon Process state machine
 * @ctx: Dependency-injection context; must not be NULL.
 * Returns: Pointer to state machine, or NULL on failure.
 *
 * @implements #19 REQ-F-LOGON-001: Logon Process state machine per Clause 12
 * @see ADR-LOGON-001 (#37)
 */
struct ieee802_1x_logon *
ieee802_1x_logon_init(struct ieee802_1x_logon_ctx *ctx);

/**
 * ieee802_1x_logon_deinit - Free the Logon Process state machine
 * @logon: State machine pointer; no-op if NULL.
 */
void ieee802_1x_logon_deinit(struct ieee802_1x_logon *logon);

/**
 * ieee802_1x_logon_sm_step - Run one step of the Logon Process state machine
 * @logon: State machine pointer.
 *
 * Evaluates pending event flags against the current state and executes
 * the matching transition from the state transition table (Section 2.3).
 * Loops until no more transitions fire (fixed-point semantics).
 *
 * @implements #19 REQ-F-LOGON-001
 */
void ieee802_1x_logon_sm_step(struct ieee802_1x_logon *logon);

/**
 * ieee802_1x_logon_port_enabled - Notify of port enable/disable event
 * @logon: State machine pointer.
 * @enabled: true if the physical port is operationally up.
 *
 * Sets pending_port_enabled or pending_port_disabled flag, then calls sm_step.
 *
 * @implements #21 REQ-F-LOGON-003
 */
void ieee802_1x_logon_port_enabled(struct ieee802_1x_logon *logon,
                                    bool enabled);

/**
 * ieee802_1x_logon_auth_success - Notify of PACP authentication success
 * @logon: State machine pointer.
 *
 * Sets pending_auth_success flag, then calls sm_step.
 *
 * @implements #21 REQ-F-LOGON-003
 */
void ieee802_1x_logon_auth_success(struct ieee802_1x_logon *logon);

/**
 * ieee802_1x_logon_auth_failure - Notify of PACP authentication failure
 * @logon: State machine pointer.
 *
 * Sets pending_auth_failure flag, then calls sm_step.
 *
 * @implements #21 REQ-F-LOGON-003
 */
void ieee802_1x_logon_auth_failure(struct ieee802_1x_logon *logon);

/**
 * ieee802_1x_logon_secured - Notify that MACsec key establishment is complete
 * @logon: State machine pointer.
 *
 * Sets pending_secured flag, then calls sm_step.
 *
 * @implements #22 REQ-F-LOGON-004
 */
void ieee802_1x_logon_secured(struct ieee802_1x_logon *logon);

/**
 * ieee802_1x_logon_get_state - Return current Logon Process state
 * @logon: State machine pointer.
 * Returns: Current state enum value.
 */
enum ieee802_1x_logon_state
ieee802_1x_logon_get_state(const struct ieee802_1x_logon *logon);

/**
 * ieee802_1x_logon_get_ctx - Return stored DI context pointer
 * @logon: State machine pointer.
 * Returns: The ieee802_1x_logon_ctx pointer passed to ieee802_1x_logon_init().
 */
struct ieee802_1x_logon_ctx *
ieee802_1x_logon_get_ctx(const struct ieee802_1x_logon *logon);
```

### 4.2 New Functions

```c
/**
 * ieee802_1x_logon_reauth_request - Request reauthentication
 * @logon: State machine pointer.
 *
 * Called by the eloop timer callback when reauth_period expires, or
 * by external trigger (wpa_cli REAUTHENTICATE). Sets pending_reauth_request
 * and calls sm_step.
 *
 * @implements #19 REQ-F-LOGON-001 (reauth path per Clause 12)
 */
void ieee802_1x_logon_reauth_request(struct ieee802_1x_logon *logon);

/**
 * ieee802_1x_logon_set_nid - Configure the target Network Identity
 * @logon: State machine pointer.
 * @nid: Pointer to NID octets (copied internally).
 * @nid_len: Length of NID in bytes (max IEEE802_1X_MAX_NID_LEN).
 * @requires_mka: True if this NID requires MACsec protection.
 * Returns: 0 on success, -1 on failure (invalid args, too long).
 *
 * Wave 1: single NID; replaces any previously set NID.
 * Must be called before port_enabled to take effect.
 *
 * @implements #20 REQ-F-LOGON-002
 */
int ieee802_1x_logon_set_nid(struct ieee802_1x_logon *logon,
                              const u8 *nid, size_t nid_len,
                              bool requires_mka);

/**
 * ieee802_1x_logon_get_nid - Query the current Network Identity
 * @logon: State machine pointer.
 * @nid_len: Output -- length of the returned NID in bytes.
 * Returns: Pointer to internal NID buffer (valid until next set_nid or deinit),
 *          or NULL if no NID is set.
 *
 * @implements #20 REQ-F-LOGON-002
 */
const u8 *ieee802_1x_logon_get_nid(const struct ieee802_1x_logon *logon,
                                     size_t *nid_len);
```

### 4.3 Internal Helper Functions (static, not in header)

```c
/**
 * logon_start_connect_timeout - Start the connect_timeout timer
 *
 * Registers an eloop timer that fires connect_timeout seconds from now,
 * calling ieee802_1x_logon_auth_failure() as a timeout-driven failure.
 */
static void logon_start_connect_timeout(struct ieee802_1x_logon *logon);

/**
 * logon_stop_connect_timeout - Cancel the connect_timeout timer
 */
static void logon_stop_connect_timeout(struct ieee802_1x_logon *logon);

/**
 * logon_start_reauth_timer - Start the reauth_period timer
 *
 * Registers an eloop timer that calls ieee802_1x_logon_reauth_request().
 */
static void logon_start_reauth_timer(struct ieee802_1x_logon *logon);

/**
 * logon_stop_reauth_timer - Cancel the reauth_period timer
 */
static void logon_stop_reauth_timer(struct ieee802_1x_logon *logon);

/**
 * logon_start_mka_wait_timer - Start the mka_wait_timeout timer
 *
 * Registers an eloop timer that fires mka_wait_timeout seconds from now,
 * calling ieee802_1x_logon_auth_failure() as a timeout-driven failure.
 */
static void logon_start_mka_wait_timer(struct ieee802_1x_logon *logon);

/**
 * logon_stop_mka_wait_timer - Cancel the mka_wait_timeout timer
 */
static void logon_stop_mka_wait_timer(struct ieee802_1x_logon *logon);

/**
 * logon_do_disconnect - Execute full disconnect sequence
 *
 * Calls logon_disconnect, kay_delete_mka (if active), signals CP
 * connect_unauthenticated, and stops all timers. Used by transitions
 * that return to DISCONNECTED (T7, T10, T15, T16, T20, T23, T25, T26).
 */
static void logon_do_disconnect(struct ieee802_1x_logon *logon);
```

### 4.4 eloop Timer Callbacks (static, not in header)

```c
/**
 * logon_connect_timeout_cb - eloop callback for connect_timeout expiry
 *
 * Calls ieee802_1x_logon_auth_failure() to trigger teardown.
 */
static void logon_connect_timeout_cb(void *eloop_ctx, void *timeout_ctx);

/**
 * logon_reauth_timer_cb - eloop callback for reauth_period expiry
 *
 * Calls ieee802_1x_logon_reauth_request() to trigger reauthentication.
 */
static void logon_reauth_timer_cb(void *eloop_ctx, void *timeout_ctx);

/**
 * logon_mka_wait_timeout_cb - eloop callback for mka_wait_timeout expiry
 *
 * Calls ieee802_1x_logon_auth_failure() to trigger teardown.
 */
static void logon_mka_wait_timeout_cb(void *eloop_ctx, void *timeout_ctx);
```

## 5. sm_step Pseudocode

The state machine step function uses a loop-until-fixed-point pattern, consistent with the existing wpa_supplicant state machine convention (`state_machine.h` SM_STEP pattern):

```
ieee802_1x_logon_sm_step(logon):
    if !logon: return
    changed = true
    while changed:
        changed = false
        switch logon->state:
            case DISCONNECTED:
                if logon->pending_port_enabled:
                    clear pending_port_enabled
                    logon->state = LOGON
                    ctx->logon_connect(ctx->ctx)
                    ctx->cp_connect_pending(ctx->ctx)
                    logon_start_connect_timeout(logon)
                    changed = true
                /* All other events are no-op in DISCONNECTED; clear them */
                clear all other pending flags
                break

            case LOGON:
                if logon->pending_port_disabled:
                    clear pending_port_disabled
                    logon_do_disconnect(logon)
                    logon->state = DISCONNECTED
                    changed = true
                elif logon->pending_auth_failure:
                    clear pending_auth_failure
                    logon_stop_connect_timeout(logon)
                    logon_do_disconnect(logon)
                    logon->state = DISCONNECTED
                    changed = true
                elif logon->pending_auth_success:
                    clear pending_auth_success
                    logon_stop_connect_timeout(logon)
                    ctx->cp_connect_authenticated(ctx->ctx)
                    if logon->nid_requires_mka:
                        ctx->kay_create_mka(ctx->ctx, &active_ckn, &active_cak,
                                            MKA_LIFE_TIME, PSK)
                        logon->mka_participant_active = true
                        logon_start_mka_wait_timer(logon)
                        logon->state = AUTHENTICATING
                    else:
                        logon_start_reauth_timer(logon)
                        logon->state = AUTHENTICATED
                    changed = true
                /* port_enabled, secured, reauth_request: no-op in LOGON */
                clear remaining pending flags
                break

            case AUTHENTICATING:
                if logon->pending_port_disabled or logon->pending_auth_failure:
                    clear flags
                    logon_stop_mka_wait_timer(logon)
                    logon_do_disconnect(logon)
                    logon->state = DISCONNECTED
                    changed = true
                elif logon->pending_secured:
                    clear pending_secured
                    logon_stop_mka_wait_timer(logon)
                    ctx->cp_connect_secure(ctx->ctx)
                    logon_start_reauth_timer(logon)
                    logon->state = SECURED
                    changed = true
                /* auth_success, reauth_request: no-op */
                clear remaining pending flags
                break

            case AUTHENTICATED:
                if logon->pending_port_disabled:
                    clear flag
                    logon_stop_reauth_timer(logon)
                    logon_do_disconnect(logon)
                    logon->state = DISCONNECTED
                    changed = true
                elif logon->pending_auth_failure:
                    clear flag
                    logon_stop_reauth_timer(logon)
                    logon_do_disconnect(logon)
                    logon->state = DISCONNECTED
                    changed = true
                elif logon->pending_reauth_request:
                    clear pending_reauth_request
                    logon_stop_reauth_timer(logon)
                    ctx->logon_connect(ctx->ctx)
                    ctx->cp_connect_pending(ctx->ctx)
                    logon_start_connect_timeout(logon)
                    logon->state = LOGON
                    changed = true
                elif logon->pending_secured:
                    clear pending_secured
                    ctx->cp_connect_secure(ctx->ctx)
                    logon_stop_reauth_timer(logon)
                    logon_start_reauth_timer(logon)
                    logon->state = SECURED
                    changed = true
                clear remaining pending flags
                break

            case SECURED:
                if logon->pending_port_disabled or logon->pending_auth_failure:
                    clear flags
                    logon_stop_reauth_timer(logon)
                    logon_do_disconnect(logon)
                    logon->state = DISCONNECTED
                    changed = true
                elif logon->pending_reauth_request:
                    clear pending_reauth_request
                    logon_stop_reauth_timer(logon)
                    ctx->logon_connect(ctx->ctx)
                    ctx->cp_connect_pending(ctx->ctx)
                    logon_start_connect_timeout(logon)
                    logon->state = LOGON
                    changed = true
                /* auth_success, secured: no-op */
                clear remaining pending flags
                break
```

## 6. Design Rationale

### 6.1 Pending-Flag Pattern

The current implementation directly mutates state inside event functions (e.g., `port_enabled` sets state and calls callbacks inline). The extended design migrates to a pending-flag pattern for all events, consistent with how wpa_supplicant state machines work (see `state_machine.h` SM_ENTER/SM_STEP). Event functions set a flag; `sm_step` evaluates and clears them. This avoids re-entrancy issues and ensures deterministic state transitions.

**Migration path**: The existing 24 tests will continue to pass because the event functions will set the pending flag and immediately call `sm_step`, preserving the same observable behavior from the test's perspective.

### 6.2 Timer Integration

Timers use the existing `eloop_register_timeout` / `eloop_cancel_timeout` API. The timer callbacks set pending event flags (e.g., connect_timeout sets `pending_auth_failure`) and call `sm_step`, ensuring all state transitions happen in the same execution context.

For unit tests, the timer callbacks will be mockable by providing test implementations that directly invoke the event functions instead of relying on `eloop`.

### 6.3 Single NID (Wave 1)

Wave 1 supports one NID at a time, set via `ieee802_1x_logon_set_nid()` from configuration. Multi-NID group management (Clause 12.5) is Wave 3 (StR-007, #30). The `nid_requires_mka` boolean replaces the full NID policy engine that Wave 3 will provide.

### 6.4 AUTHENTICATING vs AUTHENTICATED

The two-state split for post-PACP-success reflects the Clause 12 distinction between "authenticated but not yet secured" (MKA not yet established) and "fully secured." In the non-MACsec path, AUTHENTICATED is the terminal state; in the MACsec path, AUTHENTICATING is transient and leads to SECURED once the `secured` event arrives from KaY.

### 6.5 `secured` Event Instead of Polling

The design uses an event-driven model where KaY (or the wpas_logon bridge) explicitly signals `ieee802_1x_logon_secured()` when the MKA participant is fully operational. This is cleaner than having the Logon Process poll KaY state, and aligns with the function-pointer DI pattern (ADR-PAE-002, #35).

## 7. Conformance to Existing Tests

The design preserves the 24 existing passing tests. Key compatibility points:

- `ieee802_1x_logon_init` still returns non-NULL with valid ctx
- Initial state is still `LOGON_DISCONNECTED`
- `port_enabled(true)` still transitions to `LOGON_LOGON` and calls `logon_connect`
- `port_enabled(false)` still transitions to `DISCONNECTED` and calls `logon_disconnect`
- `auth_success` from LOGON/AUTHENTICATING transitions to `AUTHENTICATED` and calls `cp_connect_authenticated`
- `auth_failure` from non-DISCONNECTED transitions to `DISCONNECTED` and calls both `logon_disconnect` and `cp_connect_unauthenticated`
- `secured` from AUTHENTICATED transitions to SECURED and calls `cp_connect_secure`
- `sm_step` on LOGON signals `cp_connect_pending` and transitions to AUTHENTICATING
- `sm_step` on DISCONNECTED/AUTHENTICATED/SECURED/AUTHENTICATING is a stable no-op

The migration to pending-flag pattern is transparent: event functions set flags and immediately call `sm_step`, preserving the same state transitions and callback invocations that existing tests verify.

## 8. Application Bridge: wpas_logon.c

The `wpa_supplicant/wpas_logon.c` bridge wires concrete wpa_supplicant implementations into `ieee802_1x_logon_ctx`. It follows the existing `wpas_kay.c` pattern:

```c
/**
 * wpas_logon_init - Initialize Logon Process for a wpa_supplicant interface
 * @wpa_s: wpa_supplicant context.
 * Returns: 0 on success, -1 on failure.
 */
int wpas_logon_init(struct wpa_supplicant *wpa_s);

/**
 * wpas_logon_deinit - Deinitialize Logon Process for a wpa_supplicant interface
 * @wpa_s: wpa_supplicant context.
 */
void wpas_logon_deinit(struct wpa_supplicant *wpa_s);

/**
 * wpas_logon_rx_eapol - Feed received EAPOL frame to Logon Process
 * @wpa_s: wpa_supplicant context.
 * @src_addr: Source MAC address of the frame.
 * @buf: EAPOL frame data.
 * @len: Length of frame data.
 */
void wpas_logon_rx_eapol(struct wpa_supplicant *wpa_s,
                          const u8 *src_addr, const u8 *buf, size_t len);
```

The bridge populates `ieee802_1x_logon_ctx` with concrete callbacks that call into `eapol_sm`, `ieee802_1x_kay`, and `ieee802_1x_cp_sm` via the existing wpa_supplicant data structures.

## 9. Build Integration

```makefile
# In wpa_supplicant/Makefile -- guarded block
ifdef CONFIG_IEEE8021X_2020_LOGON
OBJS += ../src/pae/ieee802_1x_logon.o
OBJS += wpas_logon.o
CFLAGS += -DCONFIG_IEEE8021X_2020_LOGON
endif

# CONFIG_IEEE8021X_2020_LOGON implies CONFIG_IEEE8021X_2020
# Per feature flag hierarchy in ADR-COMPAT-001 (#33)
```

## 10. Traceability

| Design Element | Implements | Governed By |
|----------------|-----------|-------------|
| State transition table (Section 2) | #19 REQ-F-LOGON-001 (Logon Process SM per Clause 12) | #37 ADR-LOGON-001 |
| NID fields in struct (Section 3.1) | #20 REQ-F-LOGON-002 (NID selection) | #37 ADR-LOGON-001 |
| `logon_connect`/`logon_disconnect` callbacks | #21 REQ-F-LOGON-003 (PACP auth initiation) | #35 ADR-PAE-002 |
| `cp_connect_*` signals on transitions | #22 REQ-F-LOGON-004 (CP connectivity signalling) | #35 ADR-PAE-002 |
| `kay_create_mka`/`kay_delete_mka` in ctx (Section 3.3) | #22 REQ-F-LOGON-004 (KaY interface per Clause 12) | #35 ADR-PAE-002 |
| Timer management (Section 2.5) | #19 REQ-F-LOGON-001 (Clause 12 timer requirements) | #37 ADR-LOGON-001 |
| Pending-flag pattern (Section 6.1) | #23 REQ-NF-LOGON-001 (mockable for unit tests) | #35 ADR-PAE-002 |
| Single NID limitation (Section 6.3) | StR-003 (#3, Wave 1 scope) | #37 ADR-LOGON-001 |
| `CONFIG_IEEE8021X_2020_LOGON` gating | #4 StR-008 (backward compatibility) | #33 ADR-COMPAT-001 |

| GitHub Issue | Requirement | Design Coverage |
|-------------|-------------|-----------------|
| #19 | REQ-F-LOGON-001: Logon Process SM per Clause 12 | Full (state transition table, struct, functions, sm_step) |
| #20 | REQ-F-LOGON-002: NID selection | Wave 1: single NID via set_nid; multi-NID deferred to Wave 3 |
| #21 | REQ-F-LOGON-003: PACP authentication initiation | Full (logon_connect, auth_success/failure events, secured event) |
| #22 | REQ-F-LOGON-004: CP connectivity signalling | Full (cp_connect_* on all relevant transitions) |
| #23 | REQ-NF-LOGON-001: Mockable for unit tests | Full (function-pointer DI, pending-flag pattern, no global state) |
| #3 | StR-003: Logon Process per Clause 12 | Full (Wave 1 scope) |
| #37 | ADR-LOGON-001: New SM in src/pae/ | Governed |
| #35 | ADR-PAE-002: Function-pointer DI | Governed |
| #33 | ADR-COMPAT-001: Compile-time feature gating | Governed |
