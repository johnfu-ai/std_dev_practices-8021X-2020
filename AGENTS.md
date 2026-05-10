# AGENTS.md — IEEE 802.1X-2020 Compliance Project

> **Purpose**: Authoritative context file for AI coding agents (Claude, Copilot, Cursor, etc.) starting a new chat session.  
> Read this file before performing any analysis, design, or code generation task.

---

## Project Mission

Evolve **wpa_supplicant** (open-source C implementation) to be **fully compliant with IEEE Std 802.1X-2020** — Port-Based Network Access Control — following the engineering practices defined in this repository.

The development **must remain within the wpa_supplicant technical stack**:
- Language: **C** (not C++)
- Build system: **wpa_supplicant Makefile** (`wpa_supplicant/Makefile`, `src/*/Makefile`)
- Output: compilable and runnable wpa_supplicant binaries

---

## Workspace Layout (Multi-Root)

```
<workspace-root>/
├── wpa_supplicant-8021X-2020/      # Implementation target (wpa_supplicant C codebase)
├── 8021X-2020.md/                  # IEEE 802.1X-2020 standard (Markdown, study copy)
├── 8021X-2020.YANG/                # IEEE 802.1X-2020 official YANG data models
└── std_dev_practices-8021X-2020/   # ← YOU ARE HERE: methodology & lifecycle hub
```

### Repository Roles

| Repository | Role | Language |
|---|---|---|
| `wpa_supplicant-8021X-2020/` | Protocol implementation target | C |
| `8021X-2020.md/` | Standard reference (read-only, study only) | Markdown |
| `8021X-2020.YANG/` | Normative data model for 802.1X-2020 (reference) | YANG |
| `std_dev_practices-8021X-2020/` | Dev lifecycle, templates, methodology, agents | Markdown / Tooling |

---

## Standard Reference: IEEE 802.1X-2020

**Full title**: IEEE Standard for Local and Metropolitan Area Networks — Port-Based Network Access Control  
**Approved**: 30 January 2020 (revision of IEEE 802.1X-2010, incorporating 802.1Xbx-2014 and 802.1Xck-2018)

### Core Protocol Concepts

| Concept | Description | wpa_supplicant location |
|---|---|---|
| **PAE** (Port Access Entity) | The functional element controlling port access | `src/pae/` |
| **Supplicant PAE** | Client-side state machine requesting network access | `src/eapol_supp/eapol_supp_sm.c` |
| **Authenticator PAE** | Switch/AP-side state machine granting access | `src/eapol_auth/` |
| **EAPOL** | EAP over LAN — Ethernet frame transport for EAP | `src/eapol_supp/`, `src/eap_peer/` |
| **EAP** | Extensible Authentication Protocol | `src/eap_peer/`, `src/eap_common/` |
| **MKA** (MACsec Key Agreement) | IEEE 802.1X-2020 Clause 9 — key negotiation protocol | `src/pae/ieee802_1x_kay.c` |
| **MACsec** | IEEE 802.1AE — Ethernet frame encryption | `src/pae/ieee802_1x_cp.c` |
| **KaY** | Key Agreement entity (MKA entity) | `src/pae/ieee802_1x_kay.c` |
| **CP** (Controlled Port state machine) | Manages transition to authenticated/secure state | `src/pae/ieee802_1x_cp.c` |
| **Logon Process** | IEEE 802.1X-2020 Clause 12 — NID-aware access | Not yet implemented |
| **NID** | Network Identity — identifies a network or service | Not yet implemented |
| **ANCP** | Announced Network Connectivity Protocol | Not yet implemented |

### YANG Data Model (Normative Reference)

Located in `8021X-2020.YANG/`:

| YANG Module | Covers |
|---|---|
| `ieee802-dot1x.yang` | Top-level 802.1X management data model |
| `ieee802-dot1x-types.yang` | PAE type definitions (NID, session-id, etc.) |
| `ieee802-dot1x-eapol.yang` | EAPOL statistics and state |
| `ieee802-types.yang` | Common IEEE 802 types |

Use YANG module structures to understand normative data relationships. **Do not reproduce YANG content verbatim** in source files — reference by module name and node path.

### Standard Sections Quick Reference

When implementing a feature, **always reference the IEEE 802.1X-2020 section** in code comments:

```c
/* Implements IEEE 802.1X-2020 Clause 8.3 — Supplicant PAE state machine */
/* Implements IEEE 802.1X-2020 Clause 9 — MKA protocol */
/* Implements IEEE 802.1X-2020 Clause 12 — Logon Process */
/* Per IEEE 802.1X-2020 Table 8-3 */
```

---

## wpa_supplicant Codebase Map

```
wpa_supplicant-8021X-2020/
├── wpa_supplicant/          # Top-level application (main, config, ctrl_iface)
│   ├── wpa_supplicant.c     # Main supplicant logic
│   ├── wpas_kay.c/h         # Wpa_supplicant ↔ KaY bridge
│   ├── eapol_test.c         # Standalone EAPOL tester
│   └── defconfig            # Build configuration template
└── src/
    ├── eapol_supp/          # Supplicant EAPOL state machine (Clause 8)
    │   └── eapol_supp_sm.c  # Core supplicant state machine
    ├── eap_peer/            # EAP peer (Supplicant EAP layer)
    │   ├── eap.c            # EAP state machine
    │   ├── eap_tls.c        # EAP-TLS method
    │   ├── eap_peap.c       # EAP-PEAP method
    │   └── eap_teap.c       # EAP-TEAP method
    ├── eap_common/          # Shared EAP utilities
    ├── pae/                 # PAE / MACsec / MKA (Clause 9, 10)
    │   ├── ieee802_1x_kay.c # MKA key agreement (KaY)
    │   ├── ieee802_1x_cp.c  # Controlled Port state machine
    │   ├── ieee802_1x_key.c # Key derivation
    │   └── ieee802_1x_secy_ops.c # SecY operations abstraction
    ├── eapol_auth/          # Authenticator EAPOL state machine
    ├── crypto/              # Cryptographic primitives
    ├── tls/                 # TLS implementation
    ├── l2_packet/           # Layer-2 packet abstraction
    ├── rsn_supp/            # RSN / WPA key management
    └── utils/               # Utilities (list, os, wpa_debug, etc.)
```

### Build System

```bash
# Build wpa_supplicant
cd wpa_supplicant-8021X-2020/wpa_supplicant
cp defconfig .config
# Edit .config to enable required features (e.g. CONFIG_IEEE8021X_EAPOL=y)
make -j$(nproc)

# Build artifacts: wpa_supplicant, wpa_cli
```

Key build flags relevant to IEEE 802.1X-2020:
```makefile
CONFIG_IEEE8021X_EAPOL=y    # Core 802.1X supplicant support
CONFIG_MACSEC=y              # MACsec (IEEE 802.1AE) support
CONFIG_MOKO=y                # MKA support
CONFIG_EAP_TLS=y             # EAP-TLS authentication method
CONFIG_EAP_PEAP=y            # EAP-PEAP
CONFIG_EAP_TEAP=y            # EAP-TEAP (RFC 7170)
```

---

## Development Methodology

This project applies **7 interlocked engineering methodologies**:

### 1. IEEE/ISO/IEC Software Lifecycle (9 Phases)

```
Phase 01: Stakeholder Requirements  → 01-stakeholder-requirements/
Phase 02: Requirements Analysis     → 02-requirements/
Phase 03: Architecture Design       → 03-architecture/
Phase 04: Detailed Design           → 04-design/
Phase 05: Implementation            → 05-implementation/
Phase 06: Integration               → 06-integration/
Phase 07: Verification & Validation → 07-verification-validation/
Phase 08: Transition                → 08-transition/
Phase 09: Operation & Maintenance   → 09-operation-maintenance/
```

**Applicable standards**:
- ISO/IEC/IEEE 12207:2017 — Software life cycle processes
- ISO/IEC/IEEE 29148:2018 — Requirements engineering
- IEEE 1016-2009 — Software design descriptions
- ISO/IEC/IEEE 42010:2011 — Architecture description
- IEEE 1012-2016 — Verification and validation

### 2. Extreme Programming (XP) Core Practices

- **Test-Driven Development (TDD)** — Red → Green → Refactor; NEVER write code before a failing test
- **Continuous Integration** — Integrate multiple times per day; keep `main` green
- **Simple Design (YAGNI)** — Implement only what is needed today
- **Pair Programming** — Write production code collaboratively
- **Refactoring** — Continuously improve design while tests stay green
- **Collective Code Ownership** — Anyone can improve any code

### 3. Test-Driven Development Rules

```
1. Write a FAILING test first (Red)
2. Write MINIMUM code to make it pass (Green)  
3. Refactor while keeping tests green (Refactor)
4. Never write new production code without a failing test
```

For C code in wpa_supplicant context: use the existing test harness (`eapol_test`), or mock interfaces via function pointers for unit testing.

### 4. Domain-Driven Design (DDD)

- **Ubiquitous Language** — Use IEEE 802.1X-2020 terminology exactly as defined in the standard
  - Say "Supplicant PAE", not "client"
  - Say "Authenticator PAE", not "server-side"  
  - Say "Controlled Port", not "authenticated port"
  - Say "MKA", not "MACsec key exchange"
- **Bounded Context** — wpa_supplicant PAE is the bounded context
- **Domain Model** — Reflects state machines from IEEE 802.1X-2020 clauses

### 5. Real-Time Systems

wpa_supplicant operates in soft real-time contexts (network packet processing):
- MKA Hello Time: 2000 ms (per `src/pae/ieee802_1x_kay.h`)
- MKA Life Time: 6000 ms
- SAK Retire Time: 3000 ms
- State requirements must be **measurable**: "95th percentile EAPOL frame response < 100ms"

### 6. Object-Oriented Design Principles (in C)

Apply via C patterns:
- **Single Responsibility** — Each `.c` file has one state machine or one protocol role
- **Open/Closed** — Use function pointer tables for extensible EAP methods
- **Dependency Injection** — Pass interface structs (`ieee802_1x_cp_sm`, `ieee802_1x_kay`)
- **No global state** — All state in structs; avoid global variables

### 7. Reverse Engineering (for wpa_supplicant baseline)

Apply the reverse engineering guide (`docs/reverse-engineering-guide.md`) to:
1. Map existing state machines to IEEE 802.1X-2020 clauses
2. Identify gaps between wpa_supplicant-2.11 and IEEE 802.1X-2020
3. Document findings as GitHub Issues before changing code

---

## Traceability: GitHub Issues as Source of Truth

**All work starts with a GitHub Issue.**  
No code, no test, no design document is created without a linked issue.

### Issue ID Convention

| Prefix | Type | Example |
|---|---|---|
| `StR-NNN` | Stakeholder Requirement | `StR-001: 802.1X-2020 Compliance` |
| `REQ-F-XXX-NNN` | Functional Requirement | `REQ-F-PAE-001: Supplicant PAE state machine` |
| `REQ-NF-XXX-NNN` | Non-Functional Requirement | `REQ-NF-PERF-001: MKA hello < 2000ms` |
| `ADR-XXX-NNN` | Architecture Decision Record | `ADR-ARCH-001: Dependency injection for SecY` |
| `ARC-C-XXX-NNN` | Architecture Component | `ARC-C-PAE-001: KaY component design` |
| `TEST-XXX-NNN` | Test Case | `TEST-PAE-001: Supplicant HELD state test` |

### Code Comment Traceability

```c
/**
 * @brief Supplicant PAE state machine initialization
 *
 * Implements IEEE 802.1X-2020 Clause 8.3 Supplicant PAE state machine.
 *
 * @implements #REQ-F-PAE-001
 * @see IEEE 802.1X-2020, Clause 8.3
 */
struct eapol_sm *eapol_sm_init(struct eapol_ctx *ctx);
```

---

## Coding Rules (C, wpa_supplicant stack)

### MUST DO

```c
// ✅ Reference IEEE 802.1X-2020 section in every protocol function
// Implements IEEE 802.1X-2020 Clause 8.3.2 — CONNECTING state

// ✅ Use wpa_supplicant utility functions
#include "utils/os.h"        // os_malloc, os_free, os_memcmp
#include "utils/common.h"    // wpa_printf, wpa_hexdump
#include "utils/list.h"      // dl_list_* operations

// ✅ Dependency injection — receive context/interface via pointer
struct ieee802_1x_kay *ieee802_1x_kay_init(struct ieee802_1x_kay_ctx *ctx);

// ✅ Compile-time gating for new 802.1X-2020 features
#ifdef CONFIG_IEEE8021X_2020_LOGON
    /* IEEE 802.1X-2020 Clause 12 Logon Process */
#endif
```

### MUST NOT DO

```c
// ❌ No OS-specific headers
#include <linux/if_packet.h>    // NO
#include <sys/socket.h>         // Only via l2_packet abstraction

// ❌ No C++ constructs (this is pure C)
// ❌ No dynamic memory where static/pool allocation works
// ❌ No unbounded loops in state machine transitions
// ❌ No global variables for protocol state
// ❌ No reproduction of copyrighted standard text in comments
```

### File Naming for New 802.1X-2020 Features

```
src/pae/ieee802_1x_logon.c        # Logon Process (Clause 12)
src/pae/ieee802_1x_logon.h
src/pae/ieee802_1x_ancp.c         # ANCP handling
src/eapol_supp/eapol_supp_sm.c    # Extend existing state machine
```

### Function Documentation Template

```c
/**
 * @brief [Brief description]
 *
 * [Detailed description — implementation based on specification understanding]
 *
 * @param [param_name] [description]
 * @return [return description]
 *
 * @note Implements [IEEE 802.1X-2020 Clause/Section reference]
 * @see IEEE 802.1X-2020, Clause X.Y
 *
 * IMPORTANT: This implementation is based on understanding of IEEE 802.1X-2020
 * specification. No copyrighted content from the standard is reproduced.
 */
```

---

## AI Assets Available

This project defines 6 specialized AI agent profiles in `ai/agents/` and a focused skill library in `ai/skills/`:

| Agent | Purpose | Skills | Invocation |
|---|---|---|---|
| `@TDDDriver` | TDD Red-Green-Refactor execution, C unit tests | `wpa-tdd-implementation`, `verification-validation`, `8021x-domain-model` | `@TDDDriver implement the Supplicant PAE HELD state` |
| `@RequirementsAnalyst` | Map 802.1X-2020 clauses to GitHub issues | `requirements-traceability`, `documentation-governance`, `8021x-domain-model` | `@RequirementsAnalyst extract requirements from Clause 8` |
| `@ArchitectureStrategist` | Architecture decisions, ADRs | `architecture-governance`, `requirements-traceability`, `8021x-domain-model` | `@ArchitectureStrategist design the Logon Process integration` |
| `@TestingSpecialist` | Test coverage, test quality | `verification-validation`, `wpa-tdd-implementation`, `requirements-traceability` | `@TestingSpecialist review test coverage for ieee802_1x_kay.c` |
| `@DocumentationExpert` | Doxygen, design docs | `documentation-governance`, `requirements-traceability`, `architecture-governance` | `@DocumentationExpert document the CP state machine API` |
| `@SecurityAnalyst` | Security review, OWASP, crypto correctness | `security-review`, `8021x-domain-model`, `verification-validation` | `@SecurityAnalyst review the MKA SAK generation` |

### Skills Library (`ai/skills/`)

| Skill | Focus |
|---|---|
| `8021x-domain-model` | IEEE 802.1X-2020 clauses, YANG models, code-map, copyright-safe references |
| `requirements-traceability` | StR/REQ/ADR/ARC-C/TEST links, issue-driven development |
| `architecture-governance` | ADRs, quality scenarios, component boundaries |
| `wpa-tdd-implementation` | Test-first C changes in wpa_supplicant |
| `verification-validation` | Test planning, coverage, requirement verification |
| `security-review` | Protocol security review, secret hygiene |
| `documentation-governance` | Standards-aligned docs and repository consistency |

### Vendor-Neutral Tool Support

| Tool | Consumption Path |
|---|---|
| GitHub Copilot | `.github/` (compatibility projection synced from `ai/`) |
| Claude Code | `AGENTS.md` + `ai/` (direct) |
| Cursor | `AGENTS.md` + `ai/` (direct) |
| Other agents | `AGENTS.md` + `ai/` (direct) |

Sync `.github/` from `ai/` via: `python3 scripts/sync-ai-adapters.py`

---

## Key 802.1X-2020 Compliance Gaps (Starting Point)

Based on baseline analysis of wpa_supplicant-2.11 vs IEEE 802.1X-2020:

| Area | Current State | 802.1X-2020 Requirement | Priority |
|---|---|---|---|
| **Logon Process** | Not implemented | Clause 12 — NID-based network selection | HIGH |
| **ANCP** | Not implemented | Clause 12 — Announced Network Connectivity | HIGH |
| **MKA Clause 9 updates** | Based on 2010 spec | Review against 2020 updates | MEDIUM |
| **NID Group management** | Not implemented | Clause 12.5 — PAE NID configuration | HIGH |
| **EAP-TEAP** | Partially implemented | Required EAP method per 2020 | MEDIUM |
| **Session lifecycle** | Partial | Clause 12.5.1 — session attributes | MEDIUM |
| **YANG-model alignment** | None | Management plane per YANG models | LOW |

---

## Copyright Compliance (CRITICAL)

The `8021X-2020.md/` directory contains a study copy of the IEEE 802.1X-2020 standard.

**ABSOLUTELY FORBIDDEN**:
- Copying text, tables, or figures from the standard into source code or documentation
- Reproducing specification text verbatim in any commit, comment, or file

**PERMITTED**:
- Referencing clauses by number: "per IEEE 802.1X-2020 Clause 8.3"
- Implementing protocol logic based on your understanding of the specification
- Using protocol constants, field sizes, and timer values in implementation

---

## Quick Start for a New Chat Session

1. **Read this file** — you now have full project context
2. **Check relevant standard section** — `8021X-2020.md/8021X-2020.md` (use section search, not copy)
3. **Check YANG model** — `8021X-2020.YANG/ieee802-dot1x.yang` for data model
4. **Check existing code** — read the relevant `src/pae/` or `src/eapol_supp/` files
5. **Create a GitHub Issue** — before any code change
6. **Write failing test first** — TDD Red phase
7. **Implement minimum code** — TDD Green phase
8. **Reference standard sections** — in all function comments

---

## Related Files

| File | Purpose |
|---|---|
| `ai/instructions/root.instructions.md` | Canonical root AI instructions |
| `ai/agents/*.md` | Specialized AI agent profiles |
| `ai/skills/*/SKILL.md` | Focused IEEE 802.1X-2020 skills |
| `ai/instructions/phase-NN-*.instructions.md` | Phase-specific AI instructions |
| `docs/lifecycle-guide.md` | Full 9-phase lifecycle walkthrough |
| `docs/reverse-engineering-guide.md` | Guide for analyzing wpa_supplicant baseline |
| `docs/tdd-empirical-proof.md` | TDD methodology with empirical validation |
| `docs/real-time-systems-guide.md` | Real-time timing requirements |
| `docs/ddd-implementation-guide.md` | Domain-Driven Design patterns |
| `spec-kit-templates/` | Specification document templates |

The `.github/` directory remains as a GitHub/Copilot compatibility layer synchronized from `ai/`.
