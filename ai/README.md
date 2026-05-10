# AI Asset Layout

The `ai/` directory is the canonical home for reusable AI guidance in this repository.

## Purpose

- Keep agent, instruction, prompt, and skill content vendor-neutral.
- Let multiple tools consume the same source material.
- Preserve `.github/` as a compatibility projection for GitHub-native tooling.

## Layout

- `ai/agents/` - role-oriented agent profiles
- `ai/instructions/` - reusable task and phase guidance
- `ai/prompts/` - guided workflow prompts
- `ai/skills/` - focused, composable capabilities for IEEE 802.1X-2020 work

## Compatibility Model

Edit files in `ai/` first. Then sync `.github/` adapters from the canonical source:

```bash
python3 scripts/sync-ai-adapters.py
```

The sync step copies canonical content into `.github/`:

- `ai/instructions/root.instructions.md` → `.github/copilot-instructions.md`
- `ai/instructions/repository.instructions.md` → `.github/instructions/copilot-instructions.md`
- `ai/agents/*` → `.github/agents/`
- `ai/instructions/*` → `.github/instructions/` (excluding root and repository files)
- `ai/prompts/*` → `.github/prompts/`

## Tooling Guidance

- GitHub Copilot: consumes `.github/` compatibility files
- Claude Code / Cursor / other agents: consume `AGENTS.md` plus `ai/`
- Repository scripts and docs should refer to `ai/` as the source-of-truth

## Editing Rule

When content must change:

1. Update `ai/`.
2. Run `python3 scripts/sync-ai-adapters.py`.
3. Commit both the canonical files and the compatibility projection.
