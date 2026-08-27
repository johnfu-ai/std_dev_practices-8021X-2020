# Architecture Description

## IEEE 802.1X-2020 Compliance for wpa_supplicant

**Standard**: ISO/IEC/IEEE 42010:2011  
**Project**: wpa_supplicant IEEE 802.1X-2020 Full Compliance  
**Version**: 1.0.0  
**Date**: 2026-05-10  
**Status**: draft

---

## 1. Introduction

### 1.1 Purpose

This document describes the architecture for extending wpa_supplicant to achieve IEEE 802.1X-2020 compliance. It serves as the supplementary architecture view supporting the ADR issues that are the source of truth.

### 1.2 Scope

Wave 1 (P0) architecture decisions covering:
- Supplicant PAE / PACP update (Clause 8)
- MKA / KaY update (Clause 9)
- Logon Process addition (Clause 12)
- Backward compatibility strategy

### 1.3 References

- IEEE Std 802.1X-2020 — Port-Based Network Access Control
- ISO/IEC/IEEE 42010:2011 — Architecture Description
- ADR-ARCH-001: #32 — Extension Model
- ADR-COMPAT-001: #33 — Feature Gating Strategy
- ADR-PAE-001: #34 — PACP Update Strategy
- ADR-PAE-002: #35 — DI Pattern
- ADR-MKA-001: #36 — MKA Update Strategy
- ADR-LOGON-001: #37 — Logon Process Placement
- ADR-BASE-001: #63 — Upstream 2.12 Rebase

---

## 2. Architecture Stakeholders and Concerns

| Stakeholder | Concerns |
|---|---|
| SH-01: Protocol Conformance (Standards Body) | Correct implementation of 802.1X-2020 state machines |
| SH-02: Network Operators | Interoperability, deployment flexibility, NID-based access |
| SH-03: Security Auditors | Correct key hierarchy, no regressions in crypto |
| SH-04: wpa_supplicant Maintainers | Clean integration, minimal disruption, upstream mergeable |
| SH-05: Embedded Integrators | Binary size control, compile-time feature selection |

---

## 3. Architecture Decisions Summary

| ADR | Decision | Status | Issue |
|-----|----------|--------|-------|
| ADR-ARCH-001 | Extend wpa_supplicant in-place (not separate library) | Accepted | #32 |
| ADR-COMPAT-001 | Layered compile-time feature gating (`CONFIG_IEEE8021X_2020`) | Accepted | #33 |
| ADR-PAE-001 | Incremental PACP update with variable aliasing | Accepted | #34 |
| ADR-PAE-002 | Function-pointer DI for all inter-SM interfaces | Accepted | #35 |
| ADR-MKA-001 | Incremental KaY update, no SecY interface changes | Accepted | #36 |
| ADR-LOGON-001 | Logon Process as new SM in `src/pae/ieee802_1x_logon.c` | Accepted | #37 |
| ADR-BASE-001 | Rebase baseline to upstream wpa_supplicant 2.12; TEAP PAC removed per RFC 7170bis | Accepted | #63 |

---

## 4. Component View

### 4.1 Current Architecture (Baseline — 802.1X-2010)

```
┌──────────────────────────────────────────────────┐
│              wpa_supplicant (Application)          │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐│
│  │ config   │  │ ctrl_if  │  │ driver interface  ││
│  └──────────┘  └──────────┘  └────────┬─────────┘│
│                                       │           │
│  ┌──────────────┐   ┌────────────────┐│           │
│  │ wpas_kay.c   │   │  wpa_suppl.c   ││           │
│  │ (KaY bridge) │   │  (main logic)  ││           │
│  └──────┬───────┘   └───────┬────────┘│           │
└─────────┼───────────────────┼─────────┘           │
          │                   │                      │
┌─────────┼───────────────────┼──────────────────────┤
│ src/    │                   │                      │
│  ┌──────▼───────┐  ┌───────▼────────┐             │
│  │  pae/        │  │  eapol_supp/   │             │
│  │ ┌──────────┐ │  │ ┌────────────┐ │             │
│  │ │  KaY     │ │  │ │ Supplicant │ │             │
│  │ │ kay.c    │◄├──┤►│ PAE SM     │ │             │
│  │ └────┬─────┘ │  │ │ eapol_sm.c │ │             │
│  │      │       │  │ └────────────┘ │             │
│  │ ┌────▼─────┐ │  └────────────────┘             │
│  │ │  CP SM   │ │                                  │
│  │ │  cp.c    │ │  ┌────────────────┐             │
│  │ └────┬─────┘ │  │  eap_peer/    │             │
│  │      │       │  │  EAP methods  │             │
│  │ ┌────▼─────┐ │  └────────────────┘             │
│  │ │ SecY ops │ │                                  │
│  │ │ secy.c   │─┼──► Driver (hardware)            │
│  │ └──────────┘ │                                  │
│  └──────────────┘                                  │
└────────────────────────────────────────────────────┘
```

### 4.2 Target Architecture (802.1X-2020)

```
┌──────────────────────────────────────────────────────┐
│              wpa_supplicant (Application)              │
│  ┌───────────┐  ┌────────────┐  ┌──────────────────┐ │
│  │ config    │  │ ctrl_iface │  │ driver interface  │ │
│  └───────────┘  └────────────┘  └────────┬─────────┘ │
│                                          │            │
│  ┌──────────────┐  ┌──────────────┐      │            │
│  │ wpas_kay.c   │  │ wpas_logon.c │ NEW  │            │
│  │ (KaY bridge) │  │ (Logon brdg) │      │            │
│  └──────┬───────┘  └──────┬───────┘      │            │
└─────────┼─────────────────┼──────────────┘            │
          │                 │                            │
┌─────────┼─────────────────┼────────────────────────────┤
│ src/    │                 │                            │
│  ┌──────┼─────────────────┼────────┐                   │
│  │ pae/ │                 │        │                   │
│  │      │    ┌────────────▼──────┐ │                   │
│  │      │    │  Logon Process    │ │  NEW              │
│  │      │    │  logon.c          │ │  Clause 12        │
│  │      │    └──┬──────┬─────┬──┘ │                   │
│  │      │       │      │     │    │                   │
│  │ ┌────▼───┐ ┌─▼──┐ ┌─▼──┐ │    │  ┌──────────────┐ │
│  │ │  KaY   │ │ CP │ │    │ │    │  │ eapol_supp/  │ │
│  │ │ kay.c  │ │cp.c│ │    │ │    │  │ ┌──────────┐ │ │
│  │ │ (2020) │ │    │ │    │ └────┼──┤►│ Suppl.   │ │ │
│  │ └────┬───┘ └─┬──┘ │    │     │  │ │ PACP SM  │ │ │
│  │      │       │     │    │     │  │ │ (2020)   │ │ │
│  │ ┌────▼───────▼──┐  │    │     │  │ └──────────┘ │ │
│  │ │   SecY ops    │  │    │     │  └──────────────┘ │
│  │ │   secy.c      │──┼────┘     │                   │
│  │ └───────────────┘  │          │                   │
│  └────────────────────┘          │                   │
└──────────────────────────────────┘                   │
                                                       │
                            Driver (hardware) ◄────────┘
```

Key changes from baseline:
1. **New: Logon Process** (`ieee802_1x_logon.c`) orchestrates PACP, KaY, and CP
2. **New: `wpas_logon.c`** bridge wires Logon Process to wpa_supplicant application layer
3. **Modified: KaY** updated for 2020 Clause 9 (suspension, group CAK, SAK lifecycle)
4. **Modified: Supplicant PACP** updated for 2020 Clause 8 (new variables, Logon interface)
5. **Modified: CP** receives connect signals from Logon Process (not directly from KaY)

### 4.3 Interface Map

| Interface | From | To | Mechanism | ADR |
|-----------|------|----|-----------|-----|
| Logon→KaY | `ieee802_1x_logon` | `ieee802_1x_kay` | `ieee802_1x_logon_ctx` function pointers | #35 |
| Logon→CP | `ieee802_1x_logon` | `ieee802_1x_cp_sm` | `ieee802_1x_logon_ctx` function pointers | #35 |
| Logon→PACP | `ieee802_1x_logon` | `eapol_sm` | `ieee802_1x_pacp_logon_if` callbacks | #35 |
| KaY→SecY | `ieee802_1x_kay` | Driver | `ieee802_1x_kay_ctx` function pointers (existing) | — |
| App→Logon | `wpa_supplicant` | `ieee802_1x_logon` | `wpas_logon.c` bridge | #37 |
| App→KaY | `wpa_supplicant` | `ieee802_1x_kay` | `wpas_kay.c` bridge (existing) | — |

---

## 5. Build Architecture

### 5.1 Feature Flag Hierarchy

Per ADR-COMPAT-001 (#33):

```
CONFIG_IEEE8021X_2020          (master switch)
├── implies CONFIG_MACSEC
├── implies CONFIG_IEEE8021X_EAPOL
├── CONFIG_IEEE8021X_2020_LOGON  (Clause 12 — Logon Process)
└── CONFIG_IEEE8021X_2020_ANCP   (Clause 10 — Announcements, P1)
```

### 5.2 New Object Files

```makefile
# When CONFIG_IEEE8021X_2020 is enabled:
OBJS += ../src/pae/ieee802_1x_logon.o    # Clause 12
OBJS += wpas_logon.o                      # Application bridge

# When CONFIG_IEEE8021X_2020_ANCP is also enabled (P1):
OBJS += ../src/pae/ieee802_1x_ancp.o     # Clause 10
```

---

## 6. Implementation Wave Sequence

Per stakeholder review (2026-05-10):

### Wave 1 (P0) — Current scope

```
StR-008 (Backward Compat) ──► establish CONFIG_IEEE8021X_2020 flag
         │
         ▼
StR-001 (PAE) ──┐
                 ├──► parallel implementation
StR-002 (MKA) ──┘
         │
         ▼
StR-003 (Logon Process) ──► depends on PAE + MKA interfaces
```

### Wave 2 (P1 early)
- StR-006 (CP update) + StR-005 (EAP-TEAP) — extend existing code

### Wave 3 (P1 late)
- StR-004 (Announcements) → StR-007 (NID Groups) — new features

---

## 7. Cross-Cutting Concerns

### 7.1 Testability
- Per ADR-PAE-002 (#35): All SM interfaces use function-pointer injection
- Each SM can be tested with mock ctx structs (no hardware required)
- Existing `eapol_test` tool extended for 2020 scenarios

### 7.2 Security
- Key material handling follows existing wpa_supplicant patterns (`wpa_hexdump_key`, zeroing on free)
- CAK derivation per Clause 6.2.2 uses existing `crypto/` primitives
- No new external crypto dependencies

### 7.3 Backward Compatibility
- Per ADR-COMPAT-001 (#33): All 2020 code behind `CONFIG_IEEE8021X_2020`
- Non-regression test suite runs with flag disabled to verify zero behavioral change

---

## Traceability Matrix

| ADR Issue | Requirements Satisfied | Components Impacted |
|-----------|----------------------|---------------------|
| #32 (ADR-ARCH-001) | #1, #2, #3, #4 | All |
| #33 (ADR-COMPAT-001) | #4, #24, #25, #26 | Makefile, all source |
| #34 (ADR-PAE-001) | #5-#9, #10, #12 | `eapol_supp_sm.c` |
| #35 (ADR-PAE-002) | #6, #11, #19, #21, #23 | All SM interfaces |
| #36 (ADR-MKA-001) | #2, #13-#18 | `ieee802_1x_kay.c/h` |
| #37 (ADR-LOGON-001) | #3, #19-#23 | `ieee802_1x_logon.c/h`, `wpas_logon.c` |
