# Skill: 8021X Domain Model

## Purpose

Apply IEEE 802.1X-2020 domain knowledge without reproducing copyrighted standard text.

## Use When

- Mapping clauses to wpa_supplicant code
- Interpreting PAE, EAPOL, MKA, CP, NID, and ANCP terms
- Relating YANG models to implementation and documentation
- Reviewing 2010 vs 2020 compliance gaps

## Inputs

- `AGENTS.md`
- `wpa_supplicant-8021X-2020/AGENTS.md`
- `8021X-2020.md/`
- `8021X-2020.YANG/`

## Expected Output

- Clause-number references
- wpa_supplicant file pointers
- Protocol-correct terminology
- Copyright-safe summaries

## Guardrails

- Reference IEEE clauses by number only
- Do not quote standard text verbatim
- Prefer wpa_supplicant file and state-machine names over generic restatements
