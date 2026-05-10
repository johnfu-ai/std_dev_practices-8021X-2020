# Stakeholder Register: IEEE 802.1X-2020 Compliance Project

**Standard**: ISO/IEC/IEEE 29148:2018 (Stakeholder Requirements Definition)  
**Project**: wpa_supplicant IEEE 802.1X-2020 Full Compliance  
**Version**: 1.0.0  
**Date**: 2026-05-10  
**Status**: draft

---

## 1. Stakeholder Identification Summary

| ID | Stakeholder Class | Role | Influence | Interest | Priority |
|----|-------------------|------|-----------|----------|----------|
| SH-01 | Network Device Vendors | Embed wpa_supplicant in commercial products | High | High | Critical |
| SH-02 | Enterprise Network Operators | Deploy 802.1X-2020 for network access control | High | High | Critical |
| SH-03 | Security Certification Bodies | Certify protocol conformance and security | High | Medium | High |
| SH-04 | Open-Source Community Users | Use, extend, and contribute to wpa_supplicant | Medium | High | High |
| SH-05 | IEEE 802.1 Working Group | Define the 802.1X-2020 standard | High | Low | Medium |
| SH-06 | Authentication Server Vendors | Interoperate with 802.1X-2020 supplicants | Medium | Medium | Medium |

---

## 2. Stakeholder Profiles

### SH-01: Network Device Vendors

**Description**: Hardware and software vendors that embed wpa_supplicant as the 802.1X supplicant in their networking products — switches, access points, IoT gateways, endpoint devices, and automotive systems.

**Representatives** (archetypal):
- Product engineers integrating wpa_supplicant into device firmware
- Platform architects selecting protocol stacks for new product lines
- Quality/compliance teams ensuring standards conformance for product certification

**Concerns**:
- Full IEEE 802.1X-2020 conformance to satisfy product certification (per Clause 5, Annex A PICS)
- Stable C API/ABI to minimize integration churn across firmware releases
- Minimal resource footprint (memory, CPU) for embedded/IoT targets
- Compile-time feature gating (`#ifdef CONFIG_*`) to include only required functions
- Clear licensing (BSD) compatibility with proprietary firmware
- MACsec (IEEE 802.1AE) integration via SecY operations abstraction
- Long-term maintainability and upstream alignment with hostap.git

**Success Criteria**:
1. wpa_supplicant builds and passes all protocol tests with 802.1X-2020 features enabled
2. PICS proforma (Annex A) can be completed for Supplicant, Authenticator, and MKA roles
3. New features compile-time gated and do not increase binary size when disabled
4. No regressions in existing 802.1X-2010 functionality

**Influence/Interest**: High/High — primary consumers of the implementation.

---

### SH-02: Enterprise Network Operators

**Description**: IT organizations deploying IEEE 802.1X port-based network access control in enterprise, campus, and data center networks. They operate RADIUS/AAA infrastructure and manage network policy enforcement at scale.

**Representatives** (archetypal):
- Network security architects defining access control policy
- NOC engineers deploying and troubleshooting 802.1X on endpoints
- Identity and access management (IAM) teams integrating with AAA infrastructure

**Concerns**:
- Logon Process (Clause 12) support for NID-aware network selection — enables automated credential selection in multi-tenant or multi-VLAN environments
- MKA/MACsec (Clause 9) for LAN encryption between endpoints and switches
- EAPOL Announcements (Clause 10) to advertise available network services
- EAP-TEAP support as a modern, tunnel-based EAP method
- Interoperability with heterogeneous switch vendors' Authenticator PAEs
- Reliable session lifecycle management (Clause 12.5 session attributes)
- YANG/NETCONF management interface (Clause 14) for centralized configuration
- Backward compatibility with 802.1X-2010 infrastructure during migration

**Success Criteria**:
1. Supplicant successfully authenticates against enterprise RADIUS with EAP-TLS, EAP-PEAP, and EAP-TEAP
2. MKA session established with switches supporting MACsec, SAK distribution functional
3. Logon Process selects correct NID and credentials without manual intervention
4. EAPOL Announcements received and processed for network service discovery
5. Runtime configuration via wpa_cli / control interface for operational needs

**Influence/Interest**: High/High — drive adoption requirements and interoperability expectations.

---

### SH-03: Security Certification Bodies

**Description**: Organizations that evaluate and certify network security protocol implementations for compliance with IEEE, NIST, Common Criteria, or industry-specific standards (e.g., FIPS 140-3 for cryptographic modules, CC EAL for security targets).

**Representatives** (archetypal):
- Test lab engineers performing protocol conformance testing
- Certification assessors evaluating PICS proformas and security claims
- Cryptographic module validators (FIPS/CMVP)

**Concerns**:
- Complete PICS proforma (Annex A) coverage — every "shall" requirement verifiable
- Deterministic state machine behavior matching IEEE 802.1X-2020 clause specifications
- Correct cryptographic operations: CAK/CKN derivation (Clause 6.2), SAK generation (Clause 9), AES Key Wrap (Clause 9.12)
- No copyrighted standard text reproduced in source (copyright compliance)
- Verifiable MKA timer compliance: Hello Time (2000 ms), Life Time (6000 ms), SAK Retire Time (3000 ms) per Clause 9
- Clean separation between protocol logic and platform-specific code for testability
- Traceability from requirements to tests to implementation

**Success Criteria**:
1. Annex A PICS proforma items for Supplicant, MKA, and CP are demonstrably met
2. State machine transitions match specification clause-by-clause
3. Cryptographic key hierarchy (Clause 6.2) correctly implemented and testable in isolation
4. Timer-based behaviors measurable and within specification tolerances
5. Full test report mapping each test to an IEEE 802.1X-2020 clause

**Influence/Interest**: High/Medium — gating authority for product certification; not daily users.

---

### SH-04: Open-Source Community Users

**Description**: Developers, system administrators, and researchers who use wpa_supplicant on Linux, BSD, and other open-source platforms. They contribute patches, file bugs, and extend functionality. This class includes Linux distribution maintainers who package wpa_supplicant.

**Representatives** (archetypal):
- Linux distribution package maintainers (Debian, Fedora, Arch, etc.)
- Embedded Linux developers (OpenWrt, Yocto, Buildroot)
- Security researchers auditing protocol implementations
- Contributors to hostap.git upstream

**Concerns**:
- Code quality and readability — maintainable C following existing wpa_supplicant style
- Build system stability — wpa_supplicant Makefile, no new build system dependencies
- Backward compatibility — existing configurations and scripts continue to work
- Clear documentation of new 802.1X-2020 features and configuration options
- Incremental, reviewable patches suitable for upstream submission to hostap.git
- Debug logging (`wpa_printf`) coverage for new protocol paths
- No introduction of new external library dependencies
- Permissive licensing (BSD) preserved

**Success Criteria**:
1. All patches compile cleanly with `make -j$(nproc)` using existing Makefile
2. New features documented in `defconfig` comments and wpa_supplicant.conf examples
3. `eapol_test` exercises new 802.1X-2020 code paths
4. No regressions detected by existing test infrastructure
5. Code follows existing style conventions (function documentation, utility usage)

**Influence/Interest**: Medium/High — contributors and users; influence through code review and adoption.

---

### SH-05: IEEE 802.1 Working Group

**Description**: The IEEE standards body responsible for defining and maintaining IEEE 802.1X. They are the authoritative source for protocol specification but do not directly consume the implementation.

**Representatives**: IEEE 802.1 Working Group members (specification authors, editors).

**Concerns**:
- Correct interpretation and implementation of IEEE 802.1X-2020 normative requirements
- Feedback on specification clarity and implementability
- Reference implementation availability for interoperability testing events

**Success Criteria**:
1. Implementation demonstrates that specification is implementable
2. No misinterpretations of normative "shall" requirements

**Influence/Interest**: High/Low — defines what must be implemented; not involved in implementation decisions.

---

### SH-06: Authentication Server Vendors

**Description**: Vendors of RADIUS, Diameter, and AAA server products (e.g., FreeRADIUS, Cisco ISE, Aruba ClearPass) that must interoperate with 802.1X-2020 supplicants.

**Representatives**: AAA protocol engineers, interoperability test teams.

**Concerns**:
- Correct EAP method negotiation and session key derivation
- Interoperability of EAP-TEAP (RFC 7170) implementation
- Correct RADIUS attribute handling per RFC 3580, RFC 4675, RFC 7268

**Success Criteria**:
1. Successful EAP authentication round-trips with major AAA servers
2. Session keys (MSK) correctly derived and usable for MKA

**Influence/Interest**: Medium/Medium — interoperability dependency.

---

## 3. Stakeholder Influence/Interest Matrix

```
                    High Interest           Low Interest
              ┌─────────────────────┬─────────────────────┐
High          │  SH-01 (Vendors)    │  SH-05 (IEEE WG)    │
Influence     │  SH-02 (Enterprise) │                     │
              │  SH-03 (Cert Bodies)│                     │
              ├─────────────────────┼─────────────────────┤
Medium/Low    │  SH-04 (Community)  │  SH-06 (AAA Vendors)│
Influence     │                     │                     │
              └─────────────────────┴─────────────────────┘
```

**Engagement Strategy**:
- **SH-01, SH-02**: Manage closely — involve in requirements prioritization and acceptance testing
- **SH-03**: Keep satisfied — ensure traceability and conformance evidence
- **SH-04**: Keep informed — transparent development, clear documentation, upstream-quality patches
- **SH-05**: Monitor — reference specification, report implementability findings
- **SH-06**: Keep informed — interoperability testing coordination

---

## 4. Stakeholder Communication Plan

| Stakeholder | Communication Method | Frequency | Responsible |
|-------------|---------------------|-----------|-------------|
| SH-01 Vendors | GitHub Issues, PRs, defconfig docs | Per feature | Project lead |
| SH-02 Enterprise | Feature documentation, config examples | Per release | Project lead |
| SH-03 Cert Bodies | PICS mapping, test reports | Per milestone | Test lead |
| SH-04 Community | GitHub Issues, commit messages, README | Continuous | All contributors |
| SH-05 IEEE WG | Specification feedback (if needed) | As needed | Project lead |
| SH-06 AAA Vendors | Interoperability test results | Per release | Test lead |
