# Stakeholder Requirements Specification (StRS)

## IEEE 802.1X-2020 Full Compliance for wpa_supplicant

**Standard**: ISO/IEC/IEEE 29148:2018 (Stakeholder Requirements Definition)  
**Project**: wpa_supplicant IEEE 802.1X-2020 Full Compliance  
**Version**: 1.1.0  
**Date**: 2026-05-10  
**Status**: reviewed (stakeholder sign-off 2026-05-10)

---

## Document Purpose

This document captures the stakeholder requirements (StR) that drive the IEEE 802.1X-2020 compliance project. Each StR is the root of a traceability chain:

```
StR-NNN → REQ-F-XXX-NNN / REQ-NF-XXX-NNN → ADR-XXX-NNN → TEST-XXX-NNN → Implementation (PR)
```

Each StR listed here should be created as a GitHub Issue with label `type:stakeholder-requirement`, `phase:01-stakeholder-requirements`.

---

## StR-001: IEEE 802.1X-2020 Supplicant PAE Conformance

**GitHub Issue**: #1  
**Stakeholder Source**: SH-01 (Network Device Vendors), SH-03 (Security Certification Bodies)

**Description**:  
wpa_supplicant shall implement all mandatory Supplicant PAE functionality as defined in IEEE 802.1X-2020 Clause 5.3, Clause 5.6, and Clause 5.7, enabling vendors to complete the PICS proforma (Annex A) for the Supplicant role.

**Business Justification**:  
Vendors embedding wpa_supplicant require demonstrable conformance to the current IEEE 802.1X revision for product certification. The Supplicant PAE (Clause 8.3) is the foundational component — without conformance here, no 802.1X-2020 claim is possible.

**Success Criteria**:
1. All mandatory PICS items for Supplicant (Clause 5.6, 5.7) are satisfied
2. Supplicant PAE state machine transitions match Clause 8.3 specification
3. Existing 802.1X-2010 supplicant behavior is preserved (backward compatible)
4. State machine behavior verifiable through `eapol_test` or mock-based unit tests

**Priority**: P0 (Critical)  
**Integrity Level**: 3 (per IEEE 1012-2016 — high consequence of failure)

**Constraints**:
- Implementation in `src/eapol_supp/eapol_supp_sm.c` (extend existing code)
- Must use wpa_supplicant utility functions (`os_*`, `wpa_printf`, `dl_list_*`)

**Traceability**:
- Traces to: N/A (root stakeholder requirement)
- Refined by: #5 (REQ-F-PAE-001), #6 (REQ-F-PAE-002), #7 (REQ-F-PAE-003), #8 (REQ-F-PAE-004), #9 (REQ-F-PAE-005), #10 (REQ-NF-PERF-001), #11 (REQ-NF-TEST-001), #12 (REQ-NF-PAE-COMPAT-001)
- Verified by: *(Phase 07 TEST issues — to be created)*

---

## StR-002: MKA Protocol Compliance with IEEE 802.1X-2020 Clause 9

**GitHub Issue**: #2  
**Stakeholder Source**: SH-01 (Network Device Vendors), SH-02 (Enterprise Network Operators)

**Description**:  
wpa_supplicant shall update its MACsec Key Agreement (MKA) implementation to comply with IEEE 802.1X-2020 Clause 9, addressing all changes from the 2010 revision including updated key hierarchy, timer behaviors, and SAK distribution.

**Business Justification**:  
Enterprise networks deploying MACsec (IEEE 802.1AE) for LAN encryption depend on MKA for key negotiation. The 2010-based MKA in wpa_supplicant may not interoperate correctly with switches implementing 802.1X-2020 Authenticators, and cannot claim 2020 conformance.

**Success Criteria**:
1. MKA Hello Time (2000 ms), Life Time (6000 ms), SAK Retire Time (3000 ms) per Clause 9 verified
2. All mandatory PICS items for MKA (Clause 5.10, 5.11) satisfied
3. Key hierarchy (CAK, CKN, SAK) derivation per Clause 6.2 and Clause 9 verified
4. AES Key Wrap (Clause 9.12) correctly implemented
5. Interoperability with at least one commercial switch supporting 802.1X-2020 MKA

**Priority**: P0 (Critical)  
**Integrity Level**: 4 (cryptographic — highest consequence of failure)

**Constraints**:
- Implementation in `src/pae/ieee802_1x_kay.c` (extend existing KaY code)
- Cryptographic operations via `src/crypto/` abstractions only

**Traceability**:
- Traces to: N/A (root stakeholder requirement)
- Refined by: #13 (REQ-F-MKA-001), #14 (REQ-F-MKA-002), #15 (REQ-F-MKA-003), #16 (REQ-F-MKA-004), #17 (REQ-F-MKA-005), #18 (REQ-NF-MKA-001)
- Verified by: *(Phase 07 TEST issues — to be created)*

---

## StR-003: Logon Process Implementation (Clause 12)

**GitHub Issue**: #3  
**Stakeholder Source**: SH-02 (Enterprise Network Operators), SH-01 (Network Device Vendors)

**Description**:  
wpa_supplicant shall implement the Logon Process as specified in IEEE 802.1X-2020 Clause 12, including NID-aware network selection, CAK cache management, credential selection, and coordination of EAP authentication with MKA.

**Business Justification**:  
The Logon Process (Clause 12) is entirely missing from wpa_supplicant. It is the central coordinator that decides when to authenticate, which credentials to use, and how to select networks based on Network Identity (NID). Without it, wpa_supplicant cannot perform automated, policy-driven 802.1X-2020 network access. Enterprise operators need NID-aware logon for multi-tenant and multi-VLAN deployments.

**Success Criteria**:
1. Logon Process state machine implemented per Clause 12.1 model of operation
2. NID selection functional — selects correct credentials based on announced network identity
3. CAK cache management (Clause 6.2.3) integrated with Logon Process
4. KaY interface (Clause 12.2) — `createMKA`, `MKA.created`, `MKA.delete`, `MKA.deleted` functional
5. Coordinates EAP Supplicant and MKA as described in Clause 12.5
6. Pre-shared key (PSK) and EAP-derived key paths both supported

**Priority**: P0 (Critical)  
**Integrity Level**: 3

**Constraints**:
- New files: `src/pae/ieee802_1x_logon.c`, `src/pae/ieee802_1x_logon.h`
- Feature-gated: `#ifdef CONFIG_IEEE8021X_2020_LOGON`
- Must integrate with existing `wpas_kay.c` bridge

**Traceability**:
- Traces to: N/A (root stakeholder requirement)
- Refined by: #19 (REQ-F-LOGON-001), #20 (REQ-F-LOGON-002), #21 (REQ-F-LOGON-003), #22 (REQ-F-LOGON-004), #23 (REQ-NF-LOGON-001)
- Verified by: *(Phase 07 TEST issues — to be created)*

---

## StR-004: EAPOL Announcement Support (Clause 10)

**GitHub Issue**: #27  
**Stakeholder Source**: SH-02 (Enterprise Network Operators), SH-04 (Open-Source Community Users)

**Description**:  
wpa_supplicant shall implement reception and processing of EAPOL Announcements as specified in IEEE 802.1X-2020 Clause 10, enabling the Supplicant to discover available network services, NID sets, and MACsec cipher suites advertised by Authenticator PAEs.

**Business Justification**:  
EAPOL Announcements (Clause 10) allow Authenticators to advertise network identity information and available services before authentication begins. The Logon Process (StR-003) uses this information for NID selection. Without Announcement reception, the Supplicant operates "blind" and cannot perform automated network selection per the 802.1X-2020 model.

**Success Criteria**:
1. EAPOL-Announcement frames received and decoded per Clause 11.12
2. NID Set TLV (Clause 11.12.1) parsed and made available to Logon Process
3. Access Information TLV (Clause 11.12.2) parsed
4. MACsec Cipher Suites TLV (Clause 11.12.3) parsed
5. Key Management Domain TLV (Clause 11.12.4) parsed
6. Announcement validation per Clause 11.12.6 implemented

**Priority**: P1 (High)  
**Integrity Level**: 2

**Constraints**:
- Frame reception via existing `l2_packet` abstraction
- EAPOL frame type handling in EAPOL Transmit/Receive Process (Clause 12.8)

**Traceability**:
- Traces to: N/A (root stakeholder requirement)
- Depends on: StR-003 (Logon Process consumes Announcement data)
- Refined by: *(Phase 02 REQ-F issues — to be created)*
- Verified by: *(Phase 07 TEST issues — to be created)*

---

## StR-005: EAP-TEAP Method Completion

**GitHub Issue**: #28  
**Stakeholder Source**: SH-02 (Enterprise Network Operators), SH-06 (Authentication Server Vendors)

**Description**:  
wpa_supplicant shall complete its EAP-TEAP (RFC 7170) implementation to fully support the tunnel-based EAP method referenced by IEEE 802.1X-2020 as a recommended authentication method.

**Business Justification**:  
EAP-TEAP is positioned as the successor to EAP-PEAP and EAP-TTLS, providing improved security (channel binding, compound authentication). IEEE 802.1X-2020 references EAP-TEAP, and enterprise deployments increasingly require it. The current partial implementation limits interoperability with modern AAA servers.

**Success Criteria**:
1. EAP-TEAP completes full authentication exchange with FreeRADIUS, Cisco ISE, and Microsoft NPS
2. Inner methods (EAP-MSCHAPv2, EAP-TLS) functional within TEAP tunnel
3. Session key derivation (IMSK, EMSK) correct per RFC 7170
4. Channel binding and compound MAC verification implemented
5. PAC (Protected Access Credential) provisioning supported

**Priority**: P1 (High)  
**Integrity Level**: 3

**Constraints**:
- Implementation in `src/eap_peer/eap_teap.c` (extend existing code)
- TLS backend dependency: OpenSSL, wolfSSL, or GnuTLS

**Traceability**:
- Traces to: N/A (root stakeholder requirement)
- Refined by: *(Phase 02 REQ-F issues — to be created)*
- Verified by: *(Phase 07 TEST issues — to be created)*

---

## StR-006: Controlled Port State Machine Update (CP)

**GitHub Issue**: #29  
**Stakeholder Source**: SH-01 (Network Device Vendors), SH-03 (Security Certification Bodies)

**Description**:  
wpa_supplicant shall update the Controlled Port (CP) state machine to match IEEE 802.1X-2020 Clause 12.2 (Figure 12-2), ensuring correct coordination between the CP, KaY, and SecY/PAC for port authorization and MACsec control.

**Business Justification**:  
The CP state machine controls the `controlledPortEnabled` signal that determines whether a port can transmit and receive data. Correct CP behavior is essential for security (preventing unauthorized traffic) and interoperability (transitioning correctly between unauthenticated and authenticated states). Certification bodies require verifiable CP state machine compliance.

**Success Criteria**:
1. CP state machine transitions match Clause 12.2 / Figure 12-2
2. `controlledPortEnabled` and `portValid` signals asserted correctly
3. Unsecured connectivity mode for interoperability with non-MKA peers supported
4. SecY control variables (`macsecProtect`, `macsecValidateFrames`, `macsecReplayProtect`) correctly driven
5. State transitions testable via mock SecY interface

**Priority**: P1 (High)  
**Integrity Level**: 3

**Constraints**:
- Implementation in `src/pae/ieee802_1x_cp.c` (extend existing code)

**Traceability**:
- Traces to: N/A (root stakeholder requirement)
- Depends on: StR-002 (MKA drives CP via KaY interface)
- Refined by: *(Phase 02 REQ-F issues — to be created)*
- Verified by: *(Phase 07 TEST issues — to be created)*

---

## StR-007: NID Group Management (Clause 12.5)

**GitHub Issue**: #30  
**Stakeholder Source**: SH-02 (Enterprise Network Operators)

**Description**:  
wpa_supplicant shall support per-NID configuration groups as specified in IEEE 802.1X-2020 Clause 12.5, allowing administrators to configure credential sets, authentication policies, and access parameters for different Network Identities.

**Business Justification**:  
Enterprise environments frequently have multiple networks (employee, guest, IoT, management) on the same physical infrastructure. NID groups allow the Supplicant to automatically select the correct credentials and access policy based on the announced Network Identity, eliminating manual configuration switching.

**Success Criteria**:
1. NID group configuration supported in wpa_supplicant.conf
2. Session attributes (Clause 12.5.1) tracked per NID
3. Credential binding to NID groups functional
4. NID group selection integrated with Logon Process (StR-003)
5. wpa_cli commands for NID group status and management

**Priority**: P1 (High)  
**Integrity Level**: 2

**Constraints**:
- Configuration parsing integrated with existing wpa_supplicant config system
- Feature-gated: `#ifdef CONFIG_IEEE8021X_2020_LOGON`

**Traceability**:
- Traces to: N/A (root stakeholder requirement)
- Depends on: StR-003 (Logon Process), StR-004 (EAPOL Announcements provide NID)
- Refined by: *(Phase 02 REQ-F issues — to be created)*
- Verified by: *(Phase 07 TEST issues — to be created)*

---

## StR-008: Backward Compatibility and Non-Regression

**GitHub Issue**: #4  
**Stakeholder Source**: SH-04 (Open-Source Community Users), SH-01 (Network Device Vendors)

**Description**:  
All IEEE 802.1X-2020 enhancements shall be additive and backward compatible. Existing 802.1X-2010 functionality, configuration, and behavior shall not regress. New features shall be compile-time gated with `CONFIG_*` flags so they can be excluded from builds.

**Business Justification**:  
wpa_supplicant is deployed on millions of devices. Breaking existing functionality would cause widespread disruption. Linux distribution maintainers and device vendors require stable upgrade paths. The open-source community will reject patches that introduce regressions.

**Success Criteria**:
1. Existing test suite passes 100% with 802.1X-2020 features disabled
2. Existing test suite passes 100% with 802.1X-2020 features enabled
3. Binary size does not increase when all 802.1X-2020 `CONFIG_*` flags are disabled
4. Existing `wpa_supplicant.conf` files parse and function identically
5. No new external library dependencies required

**Priority**: P0 (Critical)  
**Integrity Level**: 3

**Constraints**:
- Compile-time gating via `#ifdef CONFIG_IEEE8021X_2020_*` preprocessor guards
- No modification of existing public API signatures

**Traceability**:
- Traces to: N/A (root stakeholder requirement)
- Refined by: #24 (REQ-NF-COMPAT-001), #25 (REQ-NF-COMPAT-002), #26 (REQ-NF-COMPAT-003)
- Verified by: *(Phase 07 TEST issues — to be created)*

---

## StR-009: Protocol Conformance Testability

**GitHub Issue**: #31  
**Stakeholder Source**: SH-03 (Security Certification Bodies), SH-04 (Open-Source Community Users)

**Description**:  
All new IEEE 802.1X-2020 protocol code shall be testable through `eapol_test`, function-pointer mock injection, or purpose-built test harnesses. Protocol state machines shall have deterministic, observable behavior suitable for conformance testing.

**Business Justification**:  
Certification bodies require verifiable evidence of conformance. The open-source community values testable code. Without testability, neither conformance claims nor code quality can be assured. TDD methodology (project requirement) mandates test-first development.

**Success Criteria**:
1. All new state machines testable via mock injection (function pointer interfaces)
2. `eapol_test` extended to exercise new 802.1X-2020 code paths
3. Test coverage >80% for new code (measured by gcov/lcov)
4. Each test traces to a specific IEEE 802.1X-2020 clause
5. Deterministic state machine behavior (no timing-dependent test failures)

**Priority**: P1 (High)  
**Integrity Level**: 3

**Constraints**:
- Test infrastructure within wpa_supplicant's existing framework
- No new test framework dependencies

**Traceability**:
- Traces to: N/A (root stakeholder requirement)
- Refined by: *(Phase 02 REQ-NF issues — to be created)*
- Verified by: *(Phase 07 — self-referential: tests prove testability)*

---

## Requirements Priority Summary

| Priority | StR ID | GitHub Issue | Title | Stakeholder |
|----------|--------|-------------|-------|-------------|
| P0 (Critical) | StR-001 | #1 | Supplicant PAE Conformance | SH-01, SH-03 |
| P0 (Critical) | StR-002 | #2 | MKA Protocol Compliance | SH-01, SH-02 |
| P0 (Critical) | StR-003 | #3 | Logon Process (Clause 12) | SH-02, SH-01 |
| P0 (Critical) | StR-008 | #4 | Backward Compatibility | SH-04, SH-01 |
| P1 (High) | StR-004 | #27 | EAPOL Announcements | SH-02, SH-04 |
| P1 (High) | StR-005 | #28 | EAP-TEAP Completion | SH-02, SH-06 |
| P1 (High) early | StR-006 | #29 | CP State Machine Update | SH-01, SH-03 |
| P1 (High) | StR-007 | #30 | NID Group Management | SH-02 |
| P1 (High) | StR-009 | #31 | Protocol Conformance Testability | SH-03, SH-04 |

---

## Explicit Scope Exclusions

The following IEEE 802.1X-2020 clauses are **out of scope** for this project (confirmed at stakeholder review 2026-05-10):

| Clause | Topic | Reason | Future |
|--------|-------|--------|--------|
| 13 | PAE MIB (SNMP) | wpa_supplicant has no SNMP agent; Clause 5.18 optional | P2/Future if SNMP is added |
| 14 | YANG Data Model | Clause 5.23 optional; no NETCONF server in wpa_supplicant | P2/Future if YANG is needed |
| 5.12 | Virtual Ports | Optional; Supplicant role excludes virtual ports per 5.12.e | N/A for Supplicant |

---

## Stakeholder Review Record

**Review Date**: 2026-05-10  
**Decisions Accepted**:

| # | Decision | Resolution |
|---|----------|------------|
| D-1 | P0/P1 priority assignments | Accepted; StR-006 flagged as early-P1 |
| D-2 | Clause 13 (MIB) out of scope | Accepted — documented above |
| D-3 | Clause 14 (YANG) out of scope | Accepted — documented above |
| D-4 | REQ-NF-COMPAT-001 naming collision (#12 vs #24) | Resolved: #12 renamed to REQ-NF-PAE-COMPAT-001 |
| D-5 | XPN cipher suite coverage | Deferred to P1 decomposition |
| D-6 | Phase 02 decomposition (22 issues) approved | Accepted |
| D-7 | Implementation wave sequence confirmed | Accepted — see below |

**Implementation Waves**:
1. **Wave 1 (P0)**: StR-008 constraints → StR-001 (PAE) + StR-002 (MKA) in parallel → StR-003 (Logon)
2. **Wave 2 (P1 early)**: StR-006 (CP update) + StR-005 (EAP-TEAP) — extend existing code
3. **Wave 3 (P1 late)**: StR-004 (Announcements) → StR-007 (NID Groups) — new features

---

## Next Steps

1. ~~**Create GitHub Issues**~~: All 9 StRs have GitHub Issues — P0: #1–#4, P1: #27–#31 ✅
2. ~~**Phase 02 Refinement (P0)**~~: All 4 P0 StRs decomposed into REQ-F/REQ-NF — issues #5–#26 ✅
3. ~~**Stakeholder Review**~~: Sign-off recorded 2026-05-10 ✅
4. **Phase 02 Refinement (P1)**: Decompose P1 StRs (#27–#31) into REQ-F/REQ-NF
5. **Phase 03 Architecture**: Begin ADRs for P0 requirements (Wave 1: PAE, MKA, Logon Process)
6. **Dependency Graph**: StR-003 → StR-004 → StR-007 form a dependency chain (Logon → Announcements → NID Groups)
