# Business Context: IEEE 802.1X-2020 Compliance for wpa_supplicant

**Standard**: ISO/IEC/IEEE 29148:2018 (Stakeholder Requirements Definition)  
**Project**: wpa_supplicant IEEE 802.1X-2020 Full Compliance  
**Version**: 1.0.0  
**Date**: 2026-05-10  
**Status**: draft

---

## 1. Business Problem

wpa_supplicant 2.11 implements IEEE 802.1X based on the 2010 revision of the standard. IEEE 802.1X-2020 (approved 30 January 2020) is the current revision, incorporating amendments 802.1Xbx-2014 and 802.1Xck-2018. Key protocol areas introduced or significantly updated in the 2020 revision are **not implemented** in wpa_supplicant, creating a conformance gap that affects:

- **Product certification**: Vendors cannot claim 802.1X-2020 conformance (Clause 5, Annex A PICS)
- **Enterprise deployment**: Modern network access control features (NID-based logon, ANCP) unavailable
- **Security posture**: Missing MKA updates and EAP-TEAP reduce security options
- **Interoperability**: Networks deploying 802.1X-2020 Authenticators may require 2020 Supplicant capabilities

## 2. Compliance Gap Summary

Based on analysis of wpa_supplicant 2.11 against IEEE 802.1X-2020:

| Gap Area | Standard Reference | Severity | Current State |
|----------|-------------------|----------|---------------|
| Logon Process | Clause 12 | Critical | Not implemented |
| NID Group Management | Clause 12.5 | Critical | Not implemented |
| ANCP (Announced Network Connectivity) | Clause 10 | High | Not implemented |
| MKA Clause 9 updates (2010→2020) | Clause 9 | High | Partial (2010 base) |
| EAP-TEAP completion | RFC 7170, referenced by 802.1X-2020 | High | Partial |
| Session lifecycle attributes | Clause 12.5.1 | Medium | Partial |
| YANG model alignment | Clause 14 | Low | None |
| PICS proforma completeness | Annex A | Medium | Not assessed |

## 3. Business Drivers

### 3.1 Standards Compliance Obligation

IEEE 802.1X-2020 is the current normative specification. Products claiming "802.1X compliant" are increasingly expected to meet the 2020 revision. Certification programs (Common Criteria, FIPS, vendor-specific programs) reference the current standard.

### 3.2 Enterprise Network Modernization

Enterprise networks are adopting MACsec (IEEE 802.1AE) for LAN-level encryption. IEEE 802.1X-2020's enhanced MKA (Clause 9) and Logon Process (Clause 12) are prerequisites for automated, NID-aware secure network access.

### 3.3 Open-Source Ecosystem Leadership

wpa_supplicant is the de facto 802.1X supplicant for Linux, Android, and many embedded platforms. Maintaining current standards compliance preserves its position and relevance.

### 3.4 Security Improvement

EAP-TEAP, updated cryptographic key hierarchy, and improved session management reduce attack surface and improve credential protection for deployments that depend on wpa_supplicant.

## 4. Project Scope

### In Scope

- Supplicant PAE state machine updates for 802.1X-2020 (Clause 8)
- MKA protocol updates for 802.1X-2020 (Clause 9)
- Controlled Port state machine updates (Clause 10 / Clause 12.2)
- Logon Process implementation (Clause 12)
- EAPOL Announcement reception and processing (Clause 10)
- EAP-TEAP completion (RFC 7170)
- NID-aware network selection (Clause 12.5)
- PICS proforma (Annex A) assessment and gap closure

### Out of Scope

- Authenticator PAE implementation (server-side — Clause 8.4 full implementation)
- SNMP MIB implementation (Clause 13)
- YANG/NETCONF management interface (Clause 14) — low priority, deferred
- IEEE 802.11 association/key agreement (specified by IEEE 802.11, not 802.1X)
- RADIUS/AAA server changes
- New build system (Meson, CMake, Bazel) — wpa_supplicant Makefile only

## 5. Constraints

| Constraint | Description |
|------------|-------------|
| Language | C only (C11); no C++ |
| Build system | wpa_supplicant Makefile — no new build systems |
| Architecture | Extend wpa_supplicant 2.11 — not a new library or wrapper |
| Dependencies | No new external library dependencies |
| Copyright | No reproduction of IEEE standard text in code or documentation |
| Upstream alignment | Patches should be structured for potential hostap.git upstream submission |
| Backward compatibility | Existing 802.1X-2010 functionality must not regress |

## 6. Assumptions

1. IEEE 802.1X-2020 study copy is available for reference (in `8021X-2020.md/`)
2. YANG data models are available for normative data structure reference (in `8021X-2020.YANG/`)
3. Development follows TDD — no production code without failing tests
4. `eapol_test` and function-pointer mock injection provide sufficient test harness for new protocol code
5. wpa_supplicant's existing abstraction layers (`l2_packet`, `os_*`, `crypto/`) are adequate for 802.1X-2020 features

## 7. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| PICS coverage (Supplicant) | 100% mandatory items | Annex A assessment |
| PICS coverage (MKA) | 100% mandatory items | Annex A assessment |
| Test coverage (new code) | >80% line coverage | gcov / lcov |
| Regression rate | 0 regressions | Existing test suite pass rate |
| Build impact (features disabled) | 0 bytes increase | Binary size comparison |
| EAP-TEAP interop | 3+ AAA servers | Interoperability test results |
