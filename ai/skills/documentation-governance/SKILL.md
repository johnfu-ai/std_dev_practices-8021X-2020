# Skill: Documentation Governance

## Purpose

Keep lifecycle documents, templates, and AI guidance consistent with the repository's real architecture and workflow.

## Use When

- Updating README, lifecycle docs, or phase guidance
- Checking for stale paths or renamed folders
- Consolidating duplicated guidance
- Explaining how AI assets are organized across tools

## Inputs

- `README.md`
- `AGENTS.md`
- `docs/`
- `ai/`
- `.github/`

## Expected Output

- Single-source documentation
- Accurate path references
- Clear compatibility notes for supported tools
- Reduced drift between docs, scripts, and repo layout

## Guardrails

- Do not leave stale path references behind
- Prefer updating canonical documents over adding parallel copies
- Make compatibility layers explicit when duplication is unavoidable
