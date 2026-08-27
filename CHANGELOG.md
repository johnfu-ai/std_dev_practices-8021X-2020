# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- 2026-08-27: Implementation base rebased from upstream wpa_supplicant 2.11
  to **2.12** (see ADR-BASE-001). Baseline references in living docs
  (README, AGENTS, agent instructions, release guide, business case,
  DESIGN-PAE-001) updated; historical/decision-time records (ADR-ARCH-001,
  StR analysis provenance) left as written.
- 2026-08-27: StR-005 success criterion 5 (EAP-TEAP PAC provisioning)
  revised — PAC support removed per upstream 2.12 / RFC 7170bis direction.
- 2026-08-27: Phase 05 test results updated to 90/90 across 6 suites
  (added NID and ANCP suites), re-verified after the 2.12 rebase.

### Added
- ADR-BASE-001: rebase decision record for the upstream 2.12 merge.
- Initial project structure from IEEE_DEV_TDD_TEMPLATE
- 9-phase ISO/IEEE lifecycle directory structure
- AI agent configurations (7 agents)
- Spec-kit templates and schemas
- CI/CD workflows
- Traceability and quality gate tooling
