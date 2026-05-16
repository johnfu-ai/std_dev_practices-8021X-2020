# Phase 08: Transition — IEEE 802.1X-2020 Release

**Standard**: ISO/IEC/IEEE 12207:2017 (Transition Process)  
**Date**: 2026-05-16  
**Status**: In Progress

---

## Build Instructions

### Prerequisites

- GCC or Clang (C11)
- OpenSSL development headers (`libssl-dev`)
- Linux nl80211 headers (`libnl-3-dev`, `libnl-genl-3-dev`)

### Build Steps

```bash
cd wpa_supplicant-8021X-2020/wpa_supplicant
cp defconfig .config
```

Enable IEEE 802.1X-2020 features in `.config`:

```makefile
CONFIG_IEEE8021X_EAPOL=y        # Core 802.1X support
CONFIG_MACSEC=y                  # MACsec (IEEE 802.1AE)
CONFIG_MOKO=y                    # MKA (Clause 9)
CONFIG_EAP_TLS=y                 # EAP-TLS
CONFIG_EAP_PEAP=y                # EAP-PEAP
CONFIG_EAP_TEAP=y                # EAP-TEAP (RFC 7170)
CONFIG_IEEE8021X_2020_LOGON=y    # Logon Process (Clause 12)
```

Build:

```bash
make -j$(nproc)
```

Artifacts: `wpa_supplicant`, `wpa_cli`

### Feature Flag Hierarchy

```
CONFIG_IEEE8021X_2020              (master switch, implies MACSEC + EAPOL)
├── CONFIG_IEEE8021X_2020_LOGON    (Clause 12 — Logon Process)
└── CONFIG_IEEE8021X_2020_ANCP     (Clause 10 — Announcements, Wave 3)
```

Per ADR-COMPAT-001 (#33): all 802.1X-2020 code is compile-time gated. Disabling the flags yields identical behavior to baseline wpa_supplicant 2.11.

---

## Runtime Configuration

### Enabling Logon Process

Add to `wpa_supplicant.conf`:

```
# Enable IEEE 802.1X-2020 Logon Process
ieee8021x_2020=1
```

### NID Configuration (Wave 1 — Static)

Wave 1 supports a single static NID configured at startup. Dynamic NID discovery via ANCP is Wave 3.

---

## Verification Before Deployment

1. Run PAE unit tests: `cd tests/pae && make test`
2. Run EAPOL functional test: `./eapol_test -c test.conf -a 127.0.0.1 -p 1812 -s testing123`
3. Verify zero regression with 802.1X-2020 flags disabled: rebuild with flags off, confirm existing test suite passes

---

## Known Limitations (Wave 1)

- Single NID only (multi-NID group management is Wave 3)
- Static NID configuration only (ANCP dynamic discovery is Wave 3)
- Supplicant role only (Authenticator PAE out of scope)
- Group CAK not yet implemented (Wave 2)
- MKA suspension/resume implemented but not yet wired to Logon Process bridge

---

## Rollback Procedure

If issues arise, disable 802.1X-2020 features by commenting out the flags in `.config`:

```makefile
# CONFIG_IEEE8021X_2020_LOGON is not set
```

Rebuild. The resulting binary is functionally identical to baseline wpa_supplicant 2.11.
