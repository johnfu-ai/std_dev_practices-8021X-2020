# Skill: wpa_supplicant TDD Implementation

## Purpose

Drive test-first implementation work in the companion wpa_supplicant repository while keeping this repository as evidence and guidance only.

## Use When

- Planning Red-Green-Refactor loops
- Locating target C files in `wpa_supplicant-8021X-2020/`
- Deciding where tests belong
- Reviewing Makefile-based build expectations

## Inputs

- `wpa_supplicant-8021X-2020/AGENTS.md`
- `05-implementation/`
- `06-integration/`
- `07-verification-validation/`

## Expected Output

- Failing tests first
- Minimal code changes in wpa_supplicant C files
- Evidence links recorded in this repo
- Narrow validation commands

## Guardrails

- Do not add C implementation code to this repository
- Use wpa_supplicant utilities and Makefiles, not a new build system
- Prefer mock injection or existing harnesses such as `eapol_test`
