# IEEE 802.1X-2020 Compliance Study — Development Lifecycle Hub

> **Study and Research Project** — This repository documents the engineering
> methodology and lifecycle artefacts for a personal study of extending
> [wpa_supplicant](https://w1.fi/wpa_supplicant/) towards IEEE 802.1X-2020
> compliance. It is **not affiliated with, endorsed by, or sponsored by IEEE,
> the wpa_supplicant project, or any standards body.**

---

## ⚠️ Important Disclaimers

### Study Purpose Only

This project is conducted **solely for personal learning, technical study, and
research** into IEEE 802.1X-2020 port-based network access control and
standards-compliant software engineering practices. It is not intended for
production use, commercial deployment, or certification.

### Intellectual Property

- **IEEE 802.1X-2020** is a standard published by the Institute of Electrical
  and Electronics Engineers (IEEE). All rights to the standard text, figures,
  and tables belong to IEEE. No standard content is reproduced in this
  repository.
- **wpa_supplicant** is an open-source project by Jouni Malinen and contributors,
  distributed under the BSD licence. This project studies and proposes
  extensions; it does not redistribute a modified wpa_supplicant binary.
- All implementation work in the companion repository
  (`wpa_supplicant-8021X-2020`) is original code based on the author's
  understanding of the specification, referencing clause numbers only.

### No Warranty

This work is provided **"as is"**, without warranty of any kind. The author
makes no claim of IEEE 802.1X-2020 conformance or certification suitability.
Use at your own risk.

---

## Methodology Reference

The development methodology framework used in this project — including the
9-phase ISO/IEEE lifecycle structure, AI-agent definitions, specification
templates, and traceability tooling — is derived from and inspired by the
**[IEEE_1588_2019](https://github.com/zarfld/IEEE_1588_2019)** project by
**Dominik Zarfl ([@zarfld](https://github.com/zarfld))**.

> IEEE 1588-2019 — Precision Time Protocol (PTPv2) Core Library  
> A standards-compliant, hardware-agnostic PTPv2 implementation applying the
> same 9-phase IEEE/ISO/IEC lifecycle methodology with TDD, DDD, and full
> GitHub Issues traceability.  
> → https://github.com/zarfld/IEEE_1588_2019

The framework from that project has been adapted here
for the IEEE 802.1X-2020 / wpa_supplicant extension context. Key adaptations:

- Build system changed from CMake (new library) to wpa_supplicant Makefile (extension)
- Implementation language restricted to C11 (no C++)
- Scope limited to extending an existing open-source stack rather than a greenfield library

---

## Repository Role

This repository is the **lifecycle documentation and traceability hub** only.
It does **not** contain C implementation code.

| Repository | Role | Visibility |
|---|---|---|
| **this repo** (`std_dev_practices-8021X-2020`) | Phase docs (01–09), requirements, architecture decisions, test specifications, AI agent prompts | Public |
| `wpa_supplicant-8021X-2020` | All C source code, unit tests, wpa_supplicant Makefile build | Public |
| `8021X-2020.YANG` | Normative IEEE 802.1X-2020 YANG data model (reference only) | Public |
| `8021X-2020.md` | IEEE 802.1X-2020 standard study copy | **Private** (IEEE copyright) |

---

## Project Scope

Extend **wpa_supplicant 2.11** — the widely deployed open-source IEEE 802.1X
supplicant implementation — to support features introduced or updated in
**IEEE Std 802.1X-2020** (revision of 802.1X-2010, incorporating 802.1Xbx-2014
and 802.1Xck-2018).

### Key 802.1X-2020 Gaps vs. wpa_supplicant 2.11

| Feature | Standard Reference | Status |
|---|---|---|
| Logon Process | Clause 12 | Not implemented |
| NID Group management | Clause 12.5 | Not implemented |
| ANCP (Announced Network Connectivity Protocol) | Clause 12 | Not implemented |
| MKA Clause 9 alignment to 2020 revision | Clause 9 | Partial (2010 baseline) |
| EAP-TEAP completion | RFC 7170 / 802.1X-2020 | Partial |

### Hard Constraints

- **Language**: C only (C11) — no C++
- **Build system**: wpa_supplicant Makefile — no CMake or Meson overlay
- **Integration mode**: Extend wpa_supplicant in-place — no new upper-layer library
- **Dependencies**: No new external dependencies beyond wpa_supplicant's existing set

---

## Repository Structure

```
std_dev_practices-8021X-2020/            ← THIS REPO
├── 01-stakeholder-requirements/         # Stakeholder identification and needs (ISO/IEC/IEEE 29148)
├── 02-requirements/                     # Functional and non-functional requirements
│   ├── functional/                      # REQ-F-XXX specifications
│   ├── non-functional/                  # REQ-NF-XXX specifications
│   ├── use-cases/                       # Use case descriptions
│   └── user-stories/                    # Given/When/Then acceptance criteria
├── 03-architecture/                     # Architecture decisions and views (ISO/IEC/IEEE 42010)
├── 04-design/                           # Detailed component designs (IEEE 1016)
├── 05-implementation/                   # Implementation evidence and TDD cycle logs (no C code)
├── 06-integration/                      # Integration test plans and assembly evidence
├── 07-verification-validation/          # Test specifications (TEST-XXX.md) and V&V results
├── 08-transition/                       # Deployment and release planning
├── 09-operation-maintenance/            # Operational guides and maintenance records
├── docs/                                # Methodology guides (TDD, DDD, real-time, XP)
├── scripts/                             # Traceability validation and repository tooling
└── spec-kit-templates/                  # ISO/IEEE-compliant specification templates

wpa_supplicant-8021X-2020/               ← IMPLEMENTATION REPO (separate)
├── src/pae/                             # PAE / MKA / CP state machines (Clauses 9–10)
│   └── tests/                           # C unit tests (mock injection pattern)
├── src/eapol_supp/                      # Supplicant EAPOL state machine (Clause 8)
├── src/eap_peer/                        # EAP methods: TLS, PEAP, TEAP
└── wpa_supplicant/eapol_test.c          # EAPOL integration test harness
```

---

## Development Methodology

This project applies 7-pillar methodology:
This project applies 7-pillar methodology:

| Pillar | Key Practices |
|---|---|
| **IEEE/ISO/IEC Lifecycle** | 9 phases (12207, 29148, 42010, 1016, 1012) |
| **Extreme Programming (XP)** | TDD, continuous integration, simple design, YAGNI |
| **Test-Driven Development** | Red → Green → Refactor; no code without a failing test |
| **Domain-Driven Design** | Ubiquitous language (IEEE 802.1X-2020 terminology), bounded context |
| **Real-Time Systems** | Measurable temporal constraints; MKA timers per standard |
| **Reverse Engineering** | Systematic gap analysis of wpa_supplicant-2.11 vs. 802.1X-2020 |
| **Object-Oriented Design (in C)** | Dependency injection, single responsibility, no global state |

### Traceability Chain

```
StR Issue (#N) → REQ-F Issue (#N) → ADR Issue (#N) → C code (PR) → TEST-XXX.md
```

All work begins with a GitHub Issue. All C functions reference the issue number
and the IEEE 802.1X-2020 clause they implement.

---

## Getting Started

### Prerequisites

- GCC or Clang (C11)
- OpenSSL development headers (`libssl-dev`)
- Linux nl80211 netlink headers (`libnl-3-dev`, `libnl-genl-3-dev`)
- Python 3.8+ (for traceability scripts)

### Build the Implementation

```bash
cd wpa_supplicant-8021X-2020/wpa_supplicant
cp defconfig .config
# Edit .config: enable IEEE8021X_EAPOL, MACSEC, EAP_TEAP
make -j$(nproc)
```

### Run EAPOL Tests (no hardware required)

```bash
./eapol_test -c test.conf -a 127.0.0.1 -p 1812 -s testing123
```

---

## AI Agents

The canonical AI guidance now lives under `ai/`, with `.github/` kept as a compatibility layer for GitHub-native tooling.

Seven specialized AI agent profiles accelerate standards-compliant development:

| Agent | Role |
|---|---|
| `@RequirementsAnalyst` | Extract and formalise IEEE 802.1X-2020 clause requirements |
| `@ArchitectureStrategist` | Define ADRs for wpa_supplicant extension points |
| `@TDDDriver` | Execute TDD Red→Green→Refactor cycles in C |
| `@TestingSpecialist` | Review test coverage and quality |
| `@DocumentationExpert` | Generate Doxygen-compliant API documentation |
| `@SecurityAnalyst` | Review MKA/SAK generation and EAPOL crypto correctness |
| `@Explore` | Read-only codebase exploration and Q&A |

Focused reusable skills are documented in `ai/skills/` so other AI tools can consume the same 802.1X-2020 domain guidance without depending on `.github/` conventions.

---

## Standards and Lifecycle References

| Standard | Role in this project |
|---|---|
| **IEEE Std 802.1X-2020** | Target compliance standard |
| **ISO/IEC/IEEE 12207:2017** | Software life cycle processes framework |
| **ISO/IEC/IEEE 29148:2018** | Requirements engineering |
| **ISO/IEC/IEEE 42010:2011** | Architecture description |
| **IEEE 1016-2009** | Software design descriptions |
| **IEEE 1012-2016** | Verification and validation |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

This is a study project; contributions, corrections, and discussion are welcome
via GitHub Issues.

---

## Acknowledgements

- **Dominik Zarfl ([@zarfld](https://github.com/zarfld))** — author of the
  [IEEE_1588_2019](https://github.com/zarfld/IEEE_1588_2019) project, whose
  the methodology framework this project adapts.
- **Jouni Malinen and wpa_supplicant contributors** — for the open-source
  wpa_supplicant implementation that this study extends.
- **IEEE 802.1 Working Group** — for the IEEE 802.1X-2020 standard.

---

## License

The lifecycle documentation, methodology guides, templates, and scripts in this
repository are released under the BSD 3-Clause Licence (same as wpa_supplicant).
See [COPYING](../wpa_supplicant-8021X-2020/COPYING) for wpa_supplicant's original
licence terms.

IEEE 802.1X-2020 is copyright © 2020 IEEE. All rights reserved. No standard
content is reproduced in this repository.
