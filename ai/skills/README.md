# AI Skills

This directory contains focused skills for IEEE 802.1X-2020 development against the wpa_supplicant codebase.

## Design Goal

Agents are broad working roles. Skills are narrower capabilities that can be combined by different tools.

## Skill Map

| Skill | Focus | Primary Agents |
|---|---|---|
| `8021x-domain-model` | IEEE 802.1X-2020 clauses, YANG, code-map, copyright-safe references | All agents |
| `requirements-traceability` | StR/REQ/ADR/ARC-C/TEST links, issue-driven development | RequirementsAnalyst |
| `architecture-governance` | ADRs, quality scenarios, component boundaries | ArchitectureStrategist |
| `wpa-tdd-implementation` | Test-first C changes in wpa_supplicant | TDDDriver |
| `verification-validation` | Test planning, coverage, requirement verification | TestingSpecialist |
| `security-review` | Protocol security review and secret hygiene | SecurityAnalyst |
| `documentation-governance` | Standards-aligned docs and repository consistency | DocumentationExpert |

## Agent-to-Skill Mapping

- `Standards Compliance Advisor`: `8021x-domain-model`, `requirements-traceability`, `architecture-governance`, `documentation-governance`
- `RequirementsAnalyst`: `requirements-traceability`, `documentation-governance`, `8021x-domain-model`
- `ArchitectureStrategist`: `architecture-governance`, `requirements-traceability`, `8021x-domain-model`
- `TDDDriver`: `wpa-tdd-implementation`, `verification-validation`, `8021x-domain-model`
- `TestingSpecialist`: `verification-validation`, `wpa-tdd-implementation`, `requirements-traceability`
- `DocumentationExpert`: `documentation-governance`, `requirements-traceability`, `architecture-governance`
- `SecurityAnalyst`: `security-review`, `8021x-domain-model`, `verification-validation`
