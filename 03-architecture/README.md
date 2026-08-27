# Phase 03: Architecture Design

**Standard**: ISO/IEC/IEEE 42010:2011

## Purpose

Define system architecture including viewpoints, concerns, architectural decisions (ADRs), and component boundaries.

## Deliverables

- Architecture Decision Records (ADRs)
- Component specifications
- Architecture views (context, component, deployment)
- Quality attribute scenarios (ATAM)
- Constraints documentation

## Status

**Wave 1 (P0) ADRs**: Complete — 6 ADRs created (#32–#37), all accepted.

## Exit Criteria

- [x] Key architectural decisions documented as ADRs (#32–#37)
- [ ] Component boundaries defined (ARC-C issues — next)
- [ ] Quality attribute scenarios evaluated (QA-SC issues — next)
- [ ] Architecture reviewed against requirements

## Directory Structure

```
03-architecture/
├── architecture-description.md  # Overall architecture summary (ISO 42010)
├── decisions/                   # Architecture Decision Records (ADRs)
│   ├── ADR-ARCH-001.md         # Extension Model (#32)
│   ├── ADR-COMPAT-001.md       # Feature Gating (#33)
│   ├── ADR-PAE-001.md          # PACP Update (#34)
│   ├── ADR-PAE-002.md          # DI Pattern (#35)
│   ├── ADR-MKA-001.md          # MKA Update (#36)
│   ├── ADR-LOGON-001.md        # Logon Process (#37)
│   └── ADR-BASE-001.md         # Upstream 2.12 Rebase (#63)
├── components/                  # Component specifications (ARC-C)
├── views/                       # Architecture views and diagrams
└── constraints/                 # Technical constraints
```

## Instructions

See `ai/instructions/phase-03-architecture.instructions.md`.
