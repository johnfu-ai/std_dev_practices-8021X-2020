# Contributing to wpa_supplicant-8021X-2020

Thank you for your interest in contributing to this IEEE 802.1X-2020 implementation!

## Development Philosophy

This project follows **standards-compliant software engineering** practices:

- **Test-Driven Development (TDD)** — Write tests BEFORE code (Red → Green → Refactor)
- **Standards-Only Implementation** — Pure protocol logic, no vendor or OS dependencies
- **Continuous Integration** — All tests must pass before merging
- **Issue-Driven Development** — All work starts with a GitHub Issue

## Getting Started

### Prerequisites

- GCC or Clang (C11)
- OpenSSL development headers (`libssl-dev`)
- Linux nl80211 headers (`libnl-3-dev`, `libnl-genl-3-dev`)
- Python 3.8+ (for traceability tooling)
- Git

> **Note**: This repo contains lifecycle docs only. All C code is in `wpa_supplicant-8021X-2020/`.

### Build & Test (in wpa_supplicant-8021X-2020 repo)

```bash
cd wpa_supplicant-8021X-2020/wpa_supplicant
cp defconfig .config
# Edit .config: enable CONFIG_IEEE8021X_EAPOL=y, CONFIG_MACSEC=y, CONFIG_EAP_TEAP=y
make -j$(nproc)

# Run EAPOL functional test
./eapol_test -c test.conf -a 127.0.0.1 -p 1812 -s testing123
```

## Contribution Workflow

1. **Create an Issue** — Describe the work (requirement, bug, feature)
2. **Fork & Branch** — Create a feature branch from `main`
3. **Write Failing Test** — TDD Red phase
4. **Implement** — TDD Green phase (minimum code to pass)
5. **Refactor** — Clean up while tests stay green
6. **Submit PR** — Reference the issue with `Fixes #N` or `Implements #N`

## Code Standards

### Architecture Rules

- **Extend wpa_supplicant** — do not create a new upper-layer library
- **C only** — no C++, no new build system on top of wpa_supplicant Makefile
- **wpa_supplicant utilities** — use `os_malloc`, `wpa_printf`, `dl_list_*`; never raw libc
- **No OS-specific includes directly** — use `l2_packet.h` abstraction, never `<linux/if_packet.h>`
- **Dependency injection** — pass context structs via pointer; no global protocol state
- **Compile-time feature flags** — gate all new 802.1X-2020 code with `#ifdef CONFIG_xxx`

### C Code Location

| New feature | File location in `wpa_supplicant-8021X-2020/` |
|---|---|
| Logon Process (Clause 12) | `src/pae/ieee802_1x_logon.c` |
| ANCP | `src/pae/ieee802_1x_ancp.c` |
| Extend Supplicant PAE (Clause 8) | `src/eapol_supp/eapol_supp_sm.c` |
| Extend MKA (Clause 9) | `src/pae/ieee802_1x_kay.c` |
| Unit tests | `src/pae/tests/test_ieee802_1x_<feature>.c` |

### C Function Documentation

```c
/**
 * ieee802_1x_logon_init - Initialize Logon Process state machine
 * @kay: KaY context
 *
 * Initializes IEEE 802.1X-2020 Logon Process per Clause 12.
 * Returns: state machine pointer, or NULL on failure
 *
 * Implements: #REQ-F-PAE-012
 * See: IEEE 802.1X-2020, Clause 12
 */
struct ieee802_1x_logon *ieee802_1x_logon_init(struct ieee802_1x_kay *kay);
```

### Commit Messages

```
feat(pae): implement Logon Process NID selection per Clause 12

Implements IEEE 802.1X-2020 Clause 12 Logon Process state machine.
Adds NID-aware network selection before EAPOL authentication.

Implements: #REQ-F-PAE-012
See: IEEE 802.1X-2020, Clause 12
```

## Pull Request Checklist

- [ ] `make -j$(nproc)` compiles without errors or warnings
- [ ] New feature guarded with `#ifdef CONFIG_xxx` flag
- [ ] `defconfig` comment added for new CONFIG flag
- [ ] Unit test added in `src/pae/tests/` or via `eapol_test`
- [ ] IEEE 802.1X-2020 clause reference in all new function headers
- [ ] No copyrighted standard text reproduced in comments
- [ ] PR description references issue(s) with `Implements #N`
- [ ] Spec document updated in `std_dev_practices-8021X-2020/07-verification-validation/`

## Reporting Issues

Use the GitHub issue templates:
- **Bug Report** — For defects in existing functionality
- **Feature Request** — For new protocol features or improvements
- **Question** — For clarification on implementation approach
