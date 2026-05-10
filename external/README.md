# External Dependencies

This directory is reserved for external dependencies managed as Git submodules or vendored copies.

## Submodule Pattern

To add an external dependency:

```bash
git submodule add https://github.com/org/repo.git external/repo
```

## Guidelines

- Pin submodules to immutable SHA commits (not branches)
- Add an adapter layer to isolate your domain from external APIs
- Document purpose, upstream URL, and update policy
- See `ai/instructions/submodules.instructions.md` for full guidance
