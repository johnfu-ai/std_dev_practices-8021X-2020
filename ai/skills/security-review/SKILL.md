# Skill: Security Review

## Purpose

Review IEEE 802.1X-2020 and wpa_supplicant changes for security flaws, cryptographic misuse, and secret-handling issues.

## Use When

- Auditing EAPOL, MKA, KaY, CP, and related flows
- Checking for credential or secret leakage in docs and scripts
- Reviewing crypto- and identity-sensitive changes
- Evaluating threat models and mitigations

## Inputs

- `wpa_supplicant-8021X-2020/src/`
- `.github/SECURITY.md`
- `docs/` security guidance
- AI prompts and agent outputs touching security-sensitive areas

## Expected Output

- Concrete findings with severity
- Attack surface notes
- Mitigation recommendations
- Secret and privacy hygiene checks

## Guardrails

- Distinguish example placeholders from live secrets
- Prefer concrete exploit paths over generic warnings
- Review both code and documentation for leakage
