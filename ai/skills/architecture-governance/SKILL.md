# Skill: Architecture Governance

## Purpose

Produce architecture decisions and design guidance that stay aligned with ISO/IEC/IEEE 42010, IEEE 1016, and the wpa_supplicant extension model.

## Use When

- Writing ADRs and ARC-C artifacts
- Evaluating component boundaries
- Describing quality attributes and trade-offs
- Preventing accidental drift into a standalone library architecture

## Inputs

- `03-architecture/`
- `04-design/`
- Root repository constraints
- Existing wpa_supplicant integration points

## Expected Output

- Clear architectural rationale
- Explicit constraints and trade-offs
- Boundaries that preserve in-place wpa_supplicant extension
- Quality scenario coverage

## Guardrails

- No new upper-layer protocol library in this repo
- No alternate build system claims for the implementation repo
- Architecture text must reflect actual code placement and integration model
