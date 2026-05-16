# Phase 09: Operation & Maintenance — IEEE 802.1X-2020

**Standard**: ISO/IEC/IEEE 12207:2017 (Maintenance Process)  
**Date**: 2026-05-17  
**Status**: Wave 1 Complete, Wave 2 In Progress

---

## Operational Monitoring

### Log Levels for Logon Process

The Logon Process emits `wpa_printf` messages prefixed with `LOGON:`:

| Level | Prefix | Meaning |
|---|---|---|
| MSG_ERROR | `LOGON: ctx must not be NULL` | Programming error — NULL context |
| MSG_DEBUG | `LOGON: initialized` | SM lifecycle events |
| MSG_DEBUG | `LOGON: port enabled -> LOGON` | State transitions |
| MSG_DEBUG | `LOGON: auth success -> AUTHENTICATED` | Authentication outcomes |
| MSG_DEBUG | `LOGON: sm_step LOGON -> AUTHENTICATING` | SM step transitions |
| MSG_DEBUG | `LOGON: secured -> SECURED` | MACsec establishment |

### Monitoring Commands

```bash
# Watch Logon Process state transitions in real time
wpa_cli -i wlan0 status | grep ieee8021x_2020

# Debug mode — full SM trace
sudo ./wpa_supplicant -D nl80211 -i wlan0 -c wpa_supplicant.conf -dd
```

---

## Maintenance Procedures

### Updating the Logon Process

1. Add new test case to `tests/pae/test_ieee802_1x_logon.c`
2. Run `make test` — verify test fails (Red)
3. Implement in `src/pae/ieee802_1x_logon.c`
4. Run `make test` — verify all tests pass (Green)
5. Refactor if needed
6. Add function declaration to `src/pae/ieee802_1x_logon.h`
7. Update DESIGN-LOGON-001.md state transition table
8. Commit with `Implements: #REQ-F-XXX-NNN` reference

### Adding a New State Machine Component

Follow the established pattern from Logon Process:
1. Create `src/pae/ieee802_1x_<component>.c` and `.h`
2. Define a DI context struct with function pointers (per ADR-PAE-002 #35)
3. Guard with `#ifdef CONFIG_IEEE8021X_2020_<COMPONENT>`
4. Add to `wpa_supplicant/Makefile` and `defconfig`
5. Create `tests/pae/test_ieee802_1x_<component>.c`
6. Add test target to `tests/pae/Makefile`

---

## Known Issues and Future Work

### Wave 2 (In Progress)

| Item | Standard Ref | Priority | Status |
|---|---|---|---|
| EAP-TEAP completion | RFC 7170 | High | Pending (#47) |
| CP Clause 10 full audit | Clause 10 | High | Partial (cp_secured_cb done) |

### Wave 3 (Planned)

| Item | Standard Ref | Priority | Status |
|---|---|---|---|
| ANCP implementation | Clause 10 | Medium | Not started (#49, #27) |
| Multi-NID group management | Clause 12.5 | Medium | Not started (#50, #20, #30) |
| Dynamic NID discovery via ANCP | Clause 10 | Low | Not started |
| Authenticator PAE support | Clause 8.4 | Low | Not started |

### Wave 1 Completed (2026-05-16)

| Item | Standard Ref | Tests |
|---|---|---|
| Logon Process SM | Clause 12 | 24 |
| MKA suspend/resume | Clause 9 | 12 |
| Group CAK support | Clause 9.3.3 | (in MKA suite) |
| PACP logon_if | Clause 8 | 9 |
| CP SECURED notification | Clause 10 | 8 |

### Defect Tracking

All defects tracked as GitHub Issues in `johnfu-ai/std_dev_practices-8021X-2020` with appropriate labels.
