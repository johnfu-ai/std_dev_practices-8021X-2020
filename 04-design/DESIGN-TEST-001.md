# DESIGN-TEST-001: Test Strategy and Test Case Design

| Field | Value |
|---|---|
| **Status** | Draft |
| **Date** | 2026-05-16 |
| **Implements** | #11 (REQ-NF-TEST-001), #23 (REQ-NF-LOGON-001) |
| **Governed By** | #35 (ADR-PAE-002), #33 (ADR-COMPAT-001) |
| **GitHub Issues** | #43 (TEST-LOGON-001), #44 (TEST-MKA-001), #45 (TEST-PAE-001), #46 (TEST-COMPAT-001) |

---

## Test Architecture

### Test Levels

| Level | Tool | Scope | Location |
|---|---|---|---|
| Unit | Custom C test harness | Single SM in isolation with mock injection | `tests/pae/test_*.c` |
| Functional | `eapol_test` | EAPOL authentication against RADIUS | `wpa_supplicant/eapol_test` |
| Integration | Full build + `make test` | All SMs wired together | `wpa_supplicant/` build |
| Regression | Build with flags off | Zero behavioral change from baseline | Full `make` |

### Mock Injection Strategy

Per ADR-PAE-002 (#35), all inter-SM communication uses function-pointer DI. This enables isolated unit testing without hardware or network dependencies.

```c
/* Example: mock context for Logon Process tests */
static struct ieee802_1x_logon_ctx mock_ctx = {
    .ctx = NULL,
    .logon_connect = mock_logon_connect,
    .logon_disconnect = mock_logon_disconnect,
    .cp_connect_authenticated = mock_cp_connect_authenticated,
    .cp_connect_secure = mock_cp_connect_secure,
    .cp_connect_pending = mock_cp_connect_pending,
    .cp_connect_unauthenticated = mock_cp_connect_unauthenticated,
};
```

### Test Harness Pattern

Tests use a lightweight C harness with no external dependencies:

```c
#define TEST(name) static void name(void)
#define RUN(name) ...
#define ASSERT_EQ(a, b) ...
#define ASSERT_NOT_NULL(p) ...
#define FAIL(msg) ...
```

Stubs required for `os_zalloc` and `wpa_printf` (linked without the full wpa_supplicant utility objects).

---

## Test Matrix: Logon Process

### TEST-LOGON-001 (#43) — Current: 24/24 PASS

| Test ID | Function | Verifies |
|---|---|---|
| TC-LOGON-INIT-001 | `test_logon_init_valid_ctx_returns_nonnull` | #19 REQ-F-LOGON-001 |
| TC-LOGON-INIT-002 | `test_logon_init_null_ctx_returns_null` | #19 |
| TC-LOGON-DEINIT-001 | `test_logon_deinit_null_is_safe` | #19 |
| TC-LOGON-INIT-003 | `test_logon_init_initial_state_is_disconnected` | #19 |
| TC-LOGON-INIT-004 | `test_logon_init_stores_ctx_pointer` | #19, #35 |
| TC-PORT-ENABLE-001 | `test_port_enabled_true_transitions_to_logon` | #21 |
| TC-PORT-ENABLE-002 | `test_port_enabled_true_calls_logon_connect` | #21 |
| TC-PORT-ENABLE-003 | `test_port_enabled_false_transitions_to_disconnected` | #21 |
| TC-PORT-ENABLE-004 | `test_port_enabled_false_calls_logon_disconnect` | #21 |
| TC-PORT-ENABLE-005 | `test_port_enabled_null_is_safe` | — |
| TC-AUTH-SUCCESS-001 | `test_auth_success_from_logon_transitions_to_authenticated` | #21, #22 |
| TC-AUTH-SUCCESS-002 | `test_auth_success_calls_cp_connect_authenticated` | #22 |
| TC-AUTH-FAILURE-001 | `test_auth_failure_from_logon_transitions_to_disconnected` | #21, #22 |
| TC-AUTH-FAILURE-002 | `test_auth_failure_calls_logon_disconnect` | #21 |
| TC-AUTH-FAILURE-003 | `test_auth_failure_calls_cp_connect_unauthenticated` | #22 |
| TC-AUTH-NULL-001 | `test_auth_null_is_safe` | — |
| TC-SECURED-001 | `test_secured_from_authenticated_transitions_to_secured` | #22 |
| TC-SECURED-002 | `test_secured_calls_cp_connect_secure` | #22 |
| TC-SECURED-003 | `test_secured_null_is_safe` | — |
| TC-SM-STEP-001 | `test_sm_step_null_is_safe` | — |
| TC-SM-STEP-002 | `test_sm_step_disconnected_stays_disconnected` | #19 |
| TC-SM-STEP-003 | `test_sm_step_logon_signals_cp_pending` | #22 |
| TC-SM-STEP-004 | `test_sm_step_logon_transitions_to_authenticating` | #19 |
| TC-SM-STEP-005 | `test_sm_step_authenticated_is_stable` | #19 |

---

## Test Matrix: MKA (Wave 1 scope)

### TEST-MKA-001 (#44) — Not yet implemented

| Test ID | Description | Verifies | Status |
|---|---|---|---|
| TC-MKA-SUSPEND-001 | `kay_suspend()` stops MKPDU tx | #17 | PENDING |
| TC-MKA-RESUME-001 | `kay_resume()` resumes MKPDU tx | #17 | PENDING |
| TC-MKA-GROUP-CAK-001 | `create_mka` with group CAK | #17 | PENDING |
| TC-MKA-HELLO-001 | Hello Time ≤ 2000ms | #18 | PENDING |
| TC-MKA-LIFE-001 | Life Time = 6000ms | #18 | PENDING |

Test file: `tests/pae/test_ieee802_1x_kay.c` (to be created)

---

## Test Matrix: Supplicant PACP (Wave 1 scope)

### TEST-PAE-001 (#45) — Not yet implemented

| Test ID | Description | Verifies | Status |
|---|---|---|---|
| TC-PAE-LOGON-IF-001 | `eapol_sm_set_logon_if` registers | #6 | PENDING |
| TC-PAE-LOGON-IF-002 | `logon_connect` triggers EAPOL Start | #6, #7 | PENDING |
| TC-PAE-LOGON-IF-003 | `logon_disconnect` clears state | #6 | PENDING |
| TC-PAE-COMPAT-001 | Zero change when flag disabled | #12 | PENDING |
| TC-PAE-TIMER-001 | `authWhileCounter` reset on `logon_connect` | #8 | PENDING |

---

## Test Matrix: Non-Regression

### TEST-COMPAT-001 (#46) — Not yet implemented

| Test ID | Description | Verifies | Status |
|---|---|---|---|
| TC-COMPAT-BUILD-001 | Build with `CONFIG_IEEE8021X_2020=n` | #24 | PENDING |
| TC-COMPAT-BUILD-002 | Build with `CONFIG_IEEE8021X_2020=y` | #24 | PASS |
| TC-COMPAT-CONFIG-001 | Existing conf options unchanged | #25 | PENDING |
| TC-COMPAT-API-001 | Public API signatures unchanged | #25 | PENDING |
| TC-COMPAT-RUN-001 | `eapol_test` same results | #26 | PENDING |
| TC-COMPAT-BIN-001 | Binary size delta < 5% | #24 | PENDING |

---

## Wave Scope

| Wave | Test Scope | Status |
|---|---|---|
| **Wave 1** | Logon Process SM (24 tests), MKA suspend/group-CAK, PACP logon_if | 24/24 Logon tests pass; MKA/PACP pending |
| **Wave 2** | EAP-TEAP, CP Clause 10 audit, full PACP state coverage | Not started |
| **Wave 3** | ANCP, multi-NID, Authenticator PAE | Not started |

---

## Coverage Summary

| Component | Tests | Pass | Coverage |
|---|---|---|---|
| Logon Process | 24 | 24 | Full state machine coverage |
| MKA (KaY) | 0 | — | Not yet tested |
| Supplicant PACP | 0 | — | Not yet tested |
| Non-Regression | 1 | 1 | Build with flag on verified |

---

## Run Instructions

```bash
# Run all PAE unit tests
cd wpa_supplicant-8021X-2020/tests/pae && make test

# Run a single test binary
cd wpa_supplicant-8021X-2020/tests/pae
make test_ieee802_1x_logon
./test_ieee802_1x_logon

# Run EAPOL functional test
cd wpa_supplicant-8021X-2020/wpa_supplicant
./eapol_test -c test.conf -a 127.0.0.1 -p 1812 -s testing123
```
