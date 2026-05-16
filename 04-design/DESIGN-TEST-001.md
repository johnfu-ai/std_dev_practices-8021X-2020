# DESIGN-TEST-001: Test Strategy and Test Case Design

| Field | Value |
|-------|-------|
| Status | Draft |
| Date | 2026-05-16 |
| Implements | REQ-NF-TEST-001 (#11), REQ-NF-LOGON-001 (#23), TEST-LOGON (#43), TEST-MKA (#44), TEST-PAE (#45), TEST-INT (#46) |
| Governed By | ADR-PAE-002 (#35), ADR-COMPAT-001 (#33), ADR-ARCH-001 (#32) |

## 1. Overview

This document specifies the test strategy and detailed test case designs for the IEEE 802.1X-2020 compliance implementation in wpa_supplicant. The testing approach follows the TDD mandate established in CLAUDE.md: write a failing test (Red) before implementation (Green), then refactor.

The project has 24 passing tests in `tests/pae/test_ieee802_1x_logon.c` covering the Logon Process state machine skeleton. This document maps all functional requirements to test cases, defines the mock injection strategy per component, and scopes testing across Waves 1, 2, and 3.

## 2. Test Strategy

### 2.1 Testing Levels

| Level | Scope | Tool | Location |
|-------|-------|------|----------|
| Unit | Individual state machines (Logon, KaY, PACP) | Custom TEST/RUN macros, mock ctx structs | `tests/pae/test_*.c` |
| Integration | Inter-SM interaction (Logon->PACP, Logon->KaY, Logon->CP) | Composed mock ctx structs | `tests/pae/test_*.c` |
| Functional | End-to-end EAPOL authentication | `eapol_test` binary | `wpa_supplicant/eapol_test` |
| Non-regression | Verify zero behavioral change when 2020 flag disabled | Full test suite with `CONFIG_IEEE8021X_2020` undefined | `tests/pae/` |

### 2.2 TDD Workflow

All feature development follows the Red-Green-Refactor cycle:

1. **Red**: Write a test that calls an unimplemented function or asserts a missing behavior. The test must compile but fail at link time or assertion.
2. **Green**: Implement the minimum code to make the test pass.
3. **Refactor**: Clean up the implementation while keeping all tests green.

### 2.3 Test Isolation

Each test is independent: it creates its own state machine instance with a fresh mock context, exercises it, and tears it down. No test depends on the side effects of a previous test. Global state (mock callback counters) is reset at the start of each test.

## 3. Test Matrix: REQ-F to Test Case Mapping

### 3.1 Logon Process (REQ-F-LOGON)

| Req ID | Issue | Requirement | Test Case IDs | Test File | Wave |
|--------|-------|-------------|---------------|-----------|------|
| REQ-F-LOGON-001 | #19 | Logon Process state machine per Clause 12 | TC-LOGON-INIT-001 through TC-LOGON-INIT-004, TC-SM-STEP-001 through TC-SM-STEP-005, TC-TRANSITION-001 through TC-TRANSITION-010 | `test_ieee802_1x_logon.c` | 1 |
| REQ-F-LOGON-002 | #20 | NID selection | TC-NID-001 through TC-NID-005 | `test_ieee802_1x_logon.c` | 1 |
| REQ-F-LOGON-003 | #21 | PACP authentication initiation | TC-PORT-ENABLE-001 through TC-PORT-ENABLE-005, TC-AUTH-SUCCESS-001, TC-AUTH-FAILURE-001 through TC-AUTH-FAILURE-003 | `test_ieee802_1x_logon.c` | 1 |
| REQ-F-LOGON-004 | #22 | CP connectivity signalling | TC-CP-001 through TC-CP-006 | `test_ieee802_1x_logon.c` | 1 |

### 3.2 MKA / KaY (REQ-F-MKA)

| Req ID | Issue | Requirement | Test Case IDs | Test File | Wave |
|--------|-------|-------------|---------------|-----------|------|
| REQ-F-MKA-001 | #13 | MKA participant state machine | TC-KAY-PARTICIPANT-001 through TC-KAY-PARTICIPANT-005 | `test_ieee802_1x_kay.c` (new) | 1 |
| REQ-F-MKA-002 | #14 | Key Server election | TC-KAY-ELECTION-001 through TC-KAY-ELECTION-003 | `test_ieee802_1x_kay.c` (new) | 1 |
| REQ-F-MKA-003 | #15 | SAK derivation and distribution | TC-KAY-SAK-001 through TC-KAY-SAK-004, TC-KAY-GROUP-CAK-001 through TC-KAY-GROUP-CAK-003 | `test_ieee802_1x_kay.c` (new) | 1 |
| REQ-F-MKA-004 | #16 | MKA timer management | TC-KAY-TIMER-001 through TC-KAY-TIMER-003 | `test_ieee802_1x_kay.c` (new) | 1 |
| REQ-F-MKA-005 | #17 | MKA suspension (2020 new) | TC-KAY-SUSPEND-001 through TC-KAY-SUSPEND-005 | `test_ieee802_1x_kay.c` (new) | 1 |

### 3.3 Supplicant PACP (REQ-F-PAE)

| Req ID | Issue | Requirement | Test Case IDs | Test File | Wave |
|--------|-------|-------------|---------------|-----------|------|
| REQ-F-PAE-001 | #5 | Supplicant PAE state machine Clause 8.3 | TC-PACP-REAUTH-001 through TC-PACP-REAUTH-003 | `test_eapol_supp_sm.c` (new) | 2 |
| REQ-F-PAE-002 | #6 | PACP variables 2020 | TC-PACP-VAR-001 through TC-PACP-VAR-004 | `test_eapol_supp_sm.c` (new) | 2 |
| REQ-F-PAE-003 | #7 | heldPeriod, quietWhile timers | TC-PACP-TIMER-001 through TC-PACP-TIMER-003 | `test_eapol_supp_sm.c` (new) | 2 |
| REQ-F-PAE-004 | #8 | portStatus reporting | TC-PACP-STATUS-001 through TC-PACP-STATUS-003 | `test_eapol_supp_sm.c` (new) | 2 |
| REQ-F-PAE-005 | #9 | Logon Process interface | TC-PACP-LOGON-IF-001 through TC-PACP-LOGON-IF-004 | `test_eapol_supp_sm.c` (new) | 2 |

## 4. Current Test Coverage: 24 Passing Tests

The current test file `tests/pae/test_ieee802_1x_logon.c` contains 24 passing tests organized by functional area:

| Area | Test Count | Test IDs |
|------|-----------|----------|
| init/deinit | 5 | TC-LOGON-INIT-001 through TC-LOGON-INIT-004, TC-LOGON-DEINIT-001 |
| port_enabled | 5 | TC-PORT-ENABLE-001 through TC-PORT-ENABLE-005 |
| auth_success | 2 | TC-AUTH-SUCCESS-001, TC-AUTH-SUCCESS-002 |
| auth_failure | 3 | TC-AUTH-FAILURE-001 through TC-AUTH-FAILURE-003 |
| NULL guards | 1 | TC-AUTH-NULL-001 |
| secured (MACsec) | 3 | TC-SECURED-001 through TC-SECURED-003 |
| sm_step | 5 | TC-SM-STEP-001 through TC-SM-STEP-005 |
| **Total** | **24** | |

### 4.1 Test Coverage Gaps

The current 24 tests cover the basic lifecycle and direct event handling. The following areas are not yet tested and require new test cases:

| Gap | Required Test Cases | Priority |
|-----|---------------------|----------|
| NID management (set_nid, get_nid) | TC-NID-001 through TC-NID-005 | Wave 1 |
| reauth_request event | TC-REAUTH-001 through TC-REAUTH-003 | Wave 1 |
| secured event from AUTHENTICATED | TC-SECURED-004 | Wave 1 |
| AUTHENTICATING state (MKA path) | TC-AUTHENTICATING-001 through TC-AUTHENTICATING-003 | Wave 1 |
| Timer expiry (connect_timeout, mka_wait) | TC-TIMER-001 through TC-TIMER-003 | Wave 1 |
| Full transition sequence (DISCONNECTED->LOGON->AUTHENTICATING->SECURED) | TC-TRANSITION-001 through TC-TRANSITION-003 | Wave 1 |
| Pending-flag pattern migration | Re-run existing 24 tests to verify no regression | Wave 1 |
| KaY suspend/resume | TC-KAY-SUSPEND-001 through TC-KAY-SUSPEND-005 | Wave 1 |
| KaY group CAK | TC-KAY-GROUP-CAK-001 through TC-KAY-GROUP-CAK-003 | Wave 1 |

## 5. Mock Injection Strategy

### 5.1 Principle

Per ADR-PAE-002 (#35), all inter-SM communication uses function-pointer dependency injection. This means every component can be tested in isolation by providing a mock `ctx` struct with callback functions that record invocations rather than performing real operations.

### 5.2 Logon Process Mock Strategy

The Logon Process uses `struct ieee802_1x_logon_ctx` for all outbound calls. Each test creates a mock context:

```c
/* Mock callback counters (file-scope statics, reset before each test) */
static int mock_logon_connect_called;
static int mock_logon_disconnect_called;
static int mock_cp_connect_authenticated_called;
static int mock_cp_connect_secure_called;
static int mock_cp_connect_pending_called;
static int mock_cp_connect_unauthenticated_called;
static int mock_kay_create_mka_called;
static int mock_kay_delete_mka_called;

/* Mock callback implementations */
static void mock_logon_connect(void *ctx) {
    (void)ctx;
    mock_logon_connect_called++;
}

/* ... similar for each callback ... */

/* Helper to create a fully-populated mock context */
static struct ieee802_1x_logon_ctx make_valid_ctx(void *opaque)
{
    struct ieee802_1x_logon_ctx ctx;
    os_memset(&ctx, 0, sizeof(ctx));
    ctx.ctx                        = opaque;
    ctx.logon_connect              = mock_logon_connect;
    ctx.logon_disconnect           = mock_logon_disconnect;
    ctx.cp_connect_authenticated   = mock_cp_connect_authenticated;
    ctx.cp_connect_secure          = mock_cp_connect_secure;
    ctx.cp_connect_pending         = mock_cp_connect_pending;
    ctx.cp_connect_unauthenticated = mock_cp_connect_unauthenticated;
    ctx.kay_create_mka             = mock_kay_create_mka;
    ctx.kay_delete_mka             = mock_kay_delete_mka;
    return ctx;
}
```

**Extensibility**: When new callbacks are added to `ieee802_1x_logon_ctx` (e.g., `kay_suspend`, `kay_resume`), the mock context helper is updated to include them, and existing tests continue to pass because the new callbacks default to NULL (the SM checks for NULL before calling).

### 5.3 KaY Mock Strategy

The KaY state machine uses `struct ieee802_1x_kay_ctx` for driver callbacks and `struct ieee802_1x_cp_sm` for CP interaction. Testing KaY requires:

1. **Driver mock**: Provide mock implementations of `ieee802_1x_kay_ctx` functions (macsec_init, enable_protect_frames, etc.) that return success without hardware.
2. **CP mock**: Provide a mock `ieee802_1x_cp_sm` that records signal_newsak, set_electedself, etc.
3. **L2 mock**: Provide a mock `l2_packet_data` that captures transmitted MKPDUs.

```c
/* KaY test helper */
static struct ieee802_1x_kay_ctx make_mock_kay_ctx(void)
{
    struct ieee802_1x_kay_ctx ctx;
    os_memset(&ctx, 0, sizeof(ctx));
    ctx.ctx = NULL;
    ctx.macsec_init = mock_macsec_init;
    ctx.macsec_deinit = mock_macsec_deinit;
    ctx.macsec_get_capability = mock_macsec_get_capability;
    ctx.enable_protect_frames = mock_enable_protect_frames;
    ctx.enable_encrypt = mock_enable_encrypt;
    ctx.set_replay_protect = mock_set_replay_protect;
    ctx.set_current_cipher_suite = mock_set_current_cipher_suite;
    ctx.enable_controlled_port = mock_enable_controlled_port;
    /* ... remaining driver callbacks ... */
    return ctx;
}
```

### 5.4 PACP Mock Strategy

The PACP (`eapol_sm`) is tested with mock `eapol_ctx` callbacks. The existing `eapol_test` tool provides a partial mock. For unit testing the 2020 additions:

1. **Logon Process mock**: Provide a mock `ieee802_1x_pacp_logon_if` that records auth_success/auth_failure invocations.
2. **EAP mock**: The existing EAP peer mock from `eapol_test` is reused.
3. **Timer mock**: The `eloop` timer system is replaced with a manual tick function for deterministic testing.

```c
/* PACP test helper */
#ifdef CONFIG_IEEE8021X_2020
static struct ieee802_1x_pacp_logon_if make_mock_logon_if(void)
{
    struct ieee802_1x_pacp_logon_if logon_if;
    os_memset(&logon_if, 0, sizeof(logon_if));
    logon_if.ctx = NULL;
    logon_if.auth_success = mock_pacp_auth_success;
    logon_if.auth_failure = mock_pacp_auth_failure;
    return logon_if;
}
#endif
```

### 5.5 Integration Test Mock Strategy

Integration tests verify the interaction between two or more state machines. The mock strategy composes real SM instances with mock boundaries at the edges:

- **Logon + PACP integration**: Real `ieee802_1x_logon` + real `eapol_sm` with mock `eapol_ctx` and mock `ieee802_1x_logon_ctx` for KaY/CP callbacks.
- **Logon + KaY integration**: Real `ieee802_1x_logon` + real `ieee802_1x_kay` with mock `ieee802_1x_kay_ctx` for driver callbacks.
- **Full Logon + PACP + KaY + CP integration**: All real SMs with mock driver callbacks. This is the closest approximation to a live system without hardware.

## 6. Wave 1 Test Scope

### 6.1 Wave 1 Test Deliverables

Wave 1 targets the Logon Process state machine and KaY 2020 additions. The following test files are in scope:

| Test File | Component | Target Test Count | Status |
|-----------|-----------|-------------------|--------|
| `test_ieee802_1x_logon.c` | Logon Process | 24 existing + ~25 new | 24 passing |
| `test_ieee802_1x_kay.c` | KaY 2020 additions | ~20 new | Not yet created |

### 6.2 Wave 1 Logon Process New Test Cases

| Test ID | Test Name | Validates | REQ-F |
|---------|-----------|-----------|-------|
| TC-NID-001 | `test_set_nid_stores_nid` | `set_nid()` copies NID bytes and sets `nid_set = true` | #20 |
| TC-NID-002 | `test_set_nid_too_long_returns_error` | NID exceeding `IEEE802_1X_MAX_NID_LEN` rejected | #20 |
| TC-NID-003 | `test_set_nid_null_returns_error` | NULL logon or NULL nid returns -1 | #20 |
| TC-NID-004 | `test_get_nid_returns_stored_nid` | `get_nid()` returns pointer and correct length | #20 |
| TC-NID-005 | `test_get_nid_unset_returns_null` | No NID configured returns NULL | #20 |
| TC-REAUTH-001 | `test_reauth_from_authenticated_to_logon` | reauth_request in AUTHENTICATED transitions to LOGON | #19 |
| TC-REAUTH-002 | `test_reauth_from_secured_to_logon` | reauth_request in SECURED transitions to LOGON | #19 |
| TC-REAUTH-003 | `test_reauth_in_disconnected_is_noop` | reauth_request in DISCONNECTED is ignored | #19 |
| TC-SECURED-004 | `test_secured_from_authenticated_via_event` | secured event in AUTHENTICATED transitions to SECURED | #22 |
| TC-AUTHENTICATING-001 | `test_auth_success_with_mka_enters_authenticating` | auth_success + nid_requires_mka -> AUTHENTICATING | #21, #22 |
| TC-AUTHENTICATING-002 | `test_secured_from_authenticating_enters_secured` | secured event in AUTHENTICATING -> SECURED | #22 |
| TC-AUTHENTICATING-003 | `test_auth_failure_from_authenticating` | auth_failure in AUTHENTICATING -> DISCONNECTED | #21 |
| TC-TIMER-001 | `test_connect_timeout_fires_auth_failure` | connect_timeout expiry triggers auth_failure | #19 |
| TC-TIMER-002 | `test_mka_wait_timeout_fires_auth_failure` | mka_wait_timeout expiry triggers auth_failure | #19 |
| TC-TIMER-003 | `test_reauth_timer_fires_reauth_request` | reauth_period expiry triggers reauth_request | #19 |
| TC-TRANSITION-001 | `test_full_path_disconnected_to_authenticated` | DISCONNECTED -> LOGON -> AUTHENTICATING -> AUTHENTICATED | #19 |
| TC-TRANSITION-002 | `test_full_path_disconnected_to_secured` | DISCONNECTED -> LOGON -> AUTHENTICATING -> SECURED | #19, #22 |
| TC-TRANSITION-003 | `test_auth_failure_returns_to_disconnected` | Failure at any point returns to DISCONNECTED | #21 |
| TC-CP-001 | `test_cp_pending_signalled_on_logon` | CP receives connect_pending on LOGON entry | #22 |
| TC-CP-002 | `test_cp_authenticated_signalled_on_auth_success` | CP receives connect_authenticated on T8/T9 | #22 |
| TC-CP-003 | `test_cp_secure_signalled_on_secured` | CP receives connect_secure on T14 | #22 |
| TC-CP-004 | `test_cp_unauthenticated_on_disconnect` | CP receives connect_unauthenticated on teardown | #22 |
| TC-CP-005 | `test_cp_pending_on_reauth` | CP receives connect_pending on reauth (T19/T24) | #22 |
| TC-CP-006 | `test_no_cp_signal_on_spurious_events` | Spurious events in wrong state do not signal CP | #22 |

### 6.3 Wave 1 KaY New Test Cases

| Test ID | Test Name | Validates | REQ-F |
|---------|-----------|-----------|-------|
| TC-KAY-SUSPEND-001 | `test_kay_suspend_sets_suspended_flag` | suspend() sets participant->suspended = true | #17 |
| TC-KAY-SUSPEND-002 | `test_kay_suspend_stops_mkpdu_tx` | Suspended participant does not transmit MKPDUs | #17 |
| TC-KAY-SUSPEND-003 | `test_kay_resume_clears_suspended_flag` | resume() clears participant->suspended | #17 |
| TC-KAY-SUSPEND-004 | `test_kay_resume_restarts_hello_timer` | Resume restarts the Hello timer | #17 |
| TC-KAY-SUSPEND-005 | `test_kay_suspend_preserves_peer_state` | Peer list unchanged during suspension | #17 |
| TC-KAY-GROUP-CAK-001 | `test_create_mka_2020_with_group_cak` | create_mka_2020 with rp_key sets is_group_cak | #15 |
| TC-KAY-GROUP-CAK-002 | `test_create_mka_2020_without_rp_key` | create_mka_2020 with NULL rp_key is same as compat | #15 |
| TC-KAY-GROUP-CAK-003 | `test_group_cak_used_for_key_derivation` | Group CAK is used for KEK/ICK derivation | #15 |
| TC-KAY-PARTICIPANT-001 | `test_participant_init_suspended_false` | New participant has suspended = false | #13 |
| TC-KAY-PARTICIPANT-002 | `test_participant_active_after_create` | Participant is active after create_mka | #13 |
| TC-KAY-PARTICIPANT-003 | `test_participant_deleted_correctly` | delete_mka removes participant from list | #13 |
| TC-KAY-ELECTION-001 | `test_key_server_election_lower_priority` | Lower priority peer becomes key server | #14 |
| TC-KAY-ELECTION-002 | `test_key_server_election_same_priority` | SCI tiebreak when priority is equal | #14 |
| TC-KAY-TIMER-001 | `test_hello_time_constant` | MKA_HELLO_TIME == 2000 ms | #16 |
| TC-KAY-TIMER-002 | `test_life_time_constant` | MKA_LIFE_TIME == 6000 ms | #16 |
| TC-KAY-TIMER-003 | `test_sak_retire_time_constant` | MKA_SAK_RETIRE_TIME == 3000 ms | #16 |

## 7. Wave 2 and Wave 3 Test Scope

### 7.1 Wave 2 (P1 early)

Wave 2 extends the PACP and CP state machines. Test scope:

| Test File | Component | Estimated Test Count |
|-----------|-----------|---------------------|
| `test_eapol_supp_sm.c` | PACP 2020 additions | ~15 |
| `test_ieee802_1x_cp.c` | CP 2020 additions | ~10 |

Key Wave 2 test areas:
- PACP Logon Process interface registration and callback invocation
- PACP variable aliases compile and resolve correctly
- PACP reAuthenticate trigger causes RESTART transition
- CP receives connect_authenticated, connect_secure, connect_pending signals
- Non-regression: PACP behavior unchanged when CONFIG_IEEE8021X_2020 is undefined

### 7.2 Wave 3 (P1 late)

Wave 3 adds ANCP and multi-NID support. Test scope:

| Test File | Component | Estimated Test Count |
|-----------|-----------|---------------------|
| `test_ieee802_1x_ancp.c` | ANCP announcements | ~15 |
| `test_ieee802_1x_logon.c` | Multi-NID extensions | ~10 |

Key Wave 3 test areas:
- ANCP frame parsing and NID extraction
- Multi-NID group management (NID priority, selection)
- Logon Process with multiple active NIDs

## 8. Non-Functional Test Cases

### 8.1 Performance Tests (REQ-NF-PERF-001, #10)

| Test ID | Test Name | Validates |
|---------|-----------|-----------|
| TC-PERF-001 | `test_eapol_response_time_p95` | EAPOL response time < 100 ms at p95 under load |

This test requires the `eapol_test` tool and a RADIUS server. It is not a unit test but a functional benchmark.

### 8.2 Backward Compatibility Tests (REQ-NF-PAE-COMPAT-001, #12; REQ-NF-COMPAT-001, #24)

| Test ID | Test Name | Validates |
|---------|-----------|-----------|
| TC-COMPAT-001 | `test_no_change_when_2020_flag_disabled` | Object files byte-identical to baseline with flag off |
| TC-COMPAT-002 | `test_existing_eapol_sm_tests_still_pass` | All pre-existing EAPOL SM tests pass with 2020 code present |

### 8.3 Testability Tests (REQ-NF-LOGON-001, #23)

| Test ID | Test Name | Validates |
|---------|-----------|-----------|
| TC-TESTABLE-001 | `test_logon_sm_instantiable_with_mock_ctx` | Logon SM can be created and driven entirely via mock callbacks |
| TC-TESTABLE-002 | `test_kay_suspend_testable_with_mock_driver` | KaY suspend/resume testable without hardware |

## 9. Test Infrastructure

### 9.1 Build System

Tests are built and run from `tests/pae/`:

```bash
# Build and run all PAE tests
cd wpa_supplicant-8021X-2020/tests/pae
make test

# Build and run a single test binary
make test_ieee802_1x_logon
./test_ieee802_1x_logon

# Build and run KaY tests (new)
make test_ieee802_1x_kay
./test_ieee802_1x_kay
```

### 9.2 Test Macros

The test framework uses the following macros (defined in each test file):

```c
#define TEST(name) static void name(void)
#define RUN(name)      /* runs test, prints pass/fail */
#define ASSERT_NOT_NULL(p)
#define ASSERT_NULL(p)
#define ASSERT_EQ(a, b)
#define FAIL(msg)
```

### 9.3 Stub Requirements

Each test file provides stubs for wpa_supplicant utilities:

| Stub | Replaces | Implementation |
|------|----------|----------------|
| `os_zalloc` | `utils/os.h` allocation | `calloc(1, size)` |
| `wpa_printf` | `utils/wpa_debug.h` debug output | Suppress (no-op) |
| `eloop_register_timeout` | `eloop.h` timer registration | Manual tick for unit tests |
| `eloop_cancel_timeout` | `eloop.h` timer cancellation | No-op or flag clear |

### 9.4 Timer Mocking Strategy

The Logon Process design introduces three timers (connect_timeout, reauth_period, mka_wait_timeout) that use `eloop_register_timeout`. For unit testing, there are two strategies:

**Strategy A: Direct Event Injection** (preferred for Wave 1)
- Skip `eloop` registration in test builds by compiling with a test-specific `eloop` stub.
- Tests directly call the timer callback functions (`logon_connect_timeout_cb`, `logon_reauth_timer_cb`, `logon_mka_wait_timeout_cb`) to simulate timer expiry.
- This gives deterministic control without requiring an event loop.

**Strategy B: Mock eloop** (for integration tests)
- Provide a simplified `eloop` implementation that advances time manually.
- Tests call `eloop_process_timeout()` to advance timers.
- More complex but allows testing of timer interactions.

Wave 1 uses Strategy A. Strategy B is reserved for integration tests in Wave 2.

## 10. Test Traceability Matrix

### 10.1 REQ-F to Test Case Mapping (Complete)

| GitHub Issue | Requirement | Test Cases | Coverage |
|-------------|-------------|------------|----------|
| #19 | REQ-F-LOGON-001: Logon Process SM | TC-LOGON-INIT-*, TC-SM-STEP-*, TC-TRANSITION-*, TC-REAUTH-*, TC-TIMER-* | Full |
| #20 | REQ-F-LOGON-002: NID selection | TC-NID-* | Full (Wave 1: single NID) |
| #21 | REQ-F-LOGON-003: PACP auth initiation | TC-PORT-ENABLE-*, TC-AUTH-SUCCESS-*, TC-AUTH-FAILURE-*, TC-AUTHENTICATING-* | Full |
| #22 | REQ-F-LOGON-004: CP connectivity signalling | TC-CP-* | Full |
| #13 | REQ-F-MKA-001: MKA participant SM | TC-KAY-PARTICIPANT-* | Full |
| #14 | REQ-F-MKA-002: Key Server election | TC-KAY-ELECTION-* | Full |
| #15 | REQ-F-MKA-003: SAK derivation/distribution | TC-KAY-SAK-*, TC-KAY-GROUP-CAK-* | Full |
| #16 | REQ-F-MKA-004: MKA timer management | TC-KAY-TIMER-* | Full |
| #17 | REQ-F-MKA-005: MKA suspension | TC-KAY-SUSPEND-* | Full |
| #5 | REQ-F-PAE-001: Supplicant PAE SM | TC-PACP-REAUTH-* | Wave 2 |
| #6 | REQ-F-PAE-002: PACP variables | TC-PACP-VAR-* | Wave 2 |
| #7 | REQ-F-PAE-003: Timers | TC-PACP-TIMER-* | Wave 2 |
| #8 | REQ-F-PAE-004: portStatus | TC-PACP-STATUS-* | Wave 2 |
| #9 | REQ-F-PAE-005: Logon Process interface | TC-PACP-LOGON-IF-* | Wave 2 |

### 10.2 REQ-NF to Test Case Mapping

| GitHub Issue | Requirement | Test Cases | Coverage |
|-------------|-------------|------------|----------|
| #10 | REQ-NF-PERF-001: EAPOL response <100 ms | TC-PERF-001 | Functional benchmark |
| #11 | REQ-NF-TEST-001: All REQ-F have test cases | This document (Section 3) | Full traceability |
| #12 | REQ-NF-PAE-COMPAT-001: Zero change when disabled | TC-COMPAT-* | Full |
| #23 | REQ-NF-LOGON-001: Mockable for unit tests | TC-TESTABLE-* | Full |
| #24 | REQ-NF-COMPAT-001: Backward compatibility | TC-COMPAT-* | Full |

## 11. Traceability

| Design Element | Implements | Governed By |
|----------------|-----------|-------------|
| Test matrix (Section 3) | #11 REQ-NF-TEST-001 (all REQ-F have test cases) | #35 ADR-PAE-002 |
| Mock injection strategy (Section 5) | #23 REQ-NF-LOGON-001 (mockable for unit tests) | #35 ADR-PAE-002 |
| Current test coverage (Section 4) | #43 TEST-LOGON (Logon Process test cases) | #37 ADR-LOGON-001 |
| KaY test cases (Section 6.3) | #44 TEST-MKA (MKA test cases) | #36 ADR-MKA-001 |
| PACP test cases (Section 7.1) | #45 TEST-PAE (PACP test cases) | #34 ADR-PAE-001 |
| Integration test cases (Section 5.5) | #46 TEST-INT (integration test cases) | #32 ADR-ARCH-001 |
| Non-regression tests (Section 8.2) | #12 REQ-NF-PAE-COMPAT-001, #24 REQ-NF-COMPAT-001 | #33 ADR-COMPAT-001 |
| Timer mocking strategy (Section 9.4) | #23 REQ-NF-LOGON-001 | #35 ADR-PAE-002 |

| GitHub Issue | Requirement | Design Coverage |
|-------------|-------------|-----------------|
| #11 | REQ-NF-TEST-001: All REQ-F have test cases | Full (Section 3: every REQ-F mapped to test IDs) |
| #23 | REQ-NF-LOGON-001: Mockable for unit tests | Full (Section 5: mock injection strategy per component) |
| #43 | TEST-LOGON: Logon Process test cases | Full (Section 4: 24 existing; Section 6.2: ~25 new planned) |
| #44 | TEST-MKA: MKA test cases | Full (Section 6.3: ~16 new planned) |
| #45 | TEST-PAE: PACP test cases | Wave 2 (Section 7.1: ~15 estimated) |
| #46 | TEST-INT: Integration test cases | Wave 2 (Section 5.5: strategy defined) |
| #12 | REQ-NF-PAE-COMPAT-001: Zero change when disabled | Full (Section 8.2) |
| #24 | REQ-NF-COMPAT-001: Backward compatibility | Full (Section 8.2) |
| #10 | REQ-NF-PERF-001: EAPOL response <100 ms | Full (Section 8.1) |
| #33 | ADR-COMPAT-001: Compile-time feature gating | Governed |
| #35 | ADR-PAE-002: Function-pointer DI | Governed (mock strategy depends on DI) |
