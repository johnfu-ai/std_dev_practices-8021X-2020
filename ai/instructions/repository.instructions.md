---
applyTo: "**"
---

# IEEE 802.1X-2020 Repository Instructions

**Canonical source**: `ai/instructions/repository.instructions.md`  
**Projected to**: `.github/instructions/copilot-instructions.md`

## Repository Scope

This repository (`std_dev_practices-8021X-2020`) is the **lifecycle documentation and traceability hub** for the IEEE 802.1X-2020 compliance project. It does **NOT** contain implementation code.

### What Lives Here
- Phase documentation (`01-stakeholder-requirements/` through `09-operation-maintenance/`)
- GitHub Issue tracking and traceability scripts
- AI agent profiles, skills, prompts, and instructions (`ai/`)
- Specification templates (`spec-kit-templates/`)

### What Lives Elsewhere
- **C implementation**: `wpa_supplicant-8021X-2020/` (wpa_supplicant Makefile, C only)
- **Standard reference**: `8021X-2020.md/` (read-only study copy)
- **YANG data models**: `8021X-2020.YANG/` (normative reference)

## Working Principles

- **Understand IEEE 802.1X-2020 protocol before documenting** — study specification thoroughly
- **No implementation-based assumptions** — use specification or analysis results only
- **Always reference IEEE 802.1X-2020 specification sections** by clause number
- **Prevent dead or orphan files** — fix existing docs rather than creating new versions
- **No ad-hoc file copies** (e.g., `*_fixed`, `*_new`) — refactor in place

## What Agents Must NOT Do in This Repository

- Generate C/C++ implementation files, CMake targets, or build system artifacts
- Create `lib/Standards/`, `include/`, or any source-code directory structure
- Suggest new build systems (Meson, Bazel, CMake) for protocol code
- Create C++ namespaces or class wrappers

## What Agents MUST Do

- Document requirements, architecture decisions, and tests in the `01-09` phase folders
- Direct all C implementation work to `wpa_supplicant-8021X-2020/src/pae/`, `src/eapol_supp/`, etc.
- Reference wpa_supplicant Makefile conventions (see `wpa_supplicant-8021X-2020/AGENTS.md`)
- Use wpa_supplicant utilities: `os_malloc`, `wpa_printf`, `dl_list_*` — never raw libc in new code

## AI Asset Layout

The `ai/` directory is the **canonical source-of-truth** for all AI guidance:

```
ai/
├── agents/        # Role-oriented agent profiles
├── instructions/  # Reusable task and phase guidance
├── prompts/       # Guided workflow prompts
└── skills/        # Focused, composable 802.1X-2020 capabilities
```

`.github/` is a **compatibility projection** for GitHub Copilot, synchronized via:

```bash
python3 scripts/sync-ai-adapters.py
```

Edit `ai/` first, then sync. Never edit `.github/agents/`, `.github/instructions/`, or `.github/prompts/` directly.

## Copyright Compliance (CRITICAL)

**ABSOLUTELY FORBIDDEN**:
- Do NOT copy text, tables, or figures from IEEE standards documents
- Do NOT reproduce specification text verbatim in comments or documentation

**PERMITTED**:
- Reference clauses by number: "per IEEE 802.1X-2020 Clause 8.3"
- Implement protocol logic based on understanding of the specification
- Use protocol constants, field sizes, and timer values in implementation

## Documentation Standards

- **IEEE 1016-2009** format for design documents
- **ISO/IEC/IEEE 42010:2011** format for architecture documents
- **ISO/IEC/IEEE 29148:2018** format for requirements
- **Markdown** format for specs (Spec-Kit compatible)

## YAML Front Matter Schema Compliance

**Authoritative Schema Sources**:
- Requirements: `spec-kit-templates/schemas/requirements-spec.schema.json`
- Architecture: `spec-kit-templates/schemas/architecture-spec.schema.json`

- Do NOT modify schemas to fit incorrect front matter
- Always validate against schemas before submitting

## Clean Submit Rules

- Each commit must pass compliance checks
- Small, single-purpose, reviewable diffs
- No dead or commented-out code
- Reference exact specification section numbers in commit messages
