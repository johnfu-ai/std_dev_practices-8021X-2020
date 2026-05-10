#!/usr/bin/env python3
"""Sync canonical AI assets from ai/ into .github/ compatibility paths."""
from __future__ import annotations

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AI_DIR = ROOT / 'ai'
GITHUB_DIR = ROOT / '.github'

DIRECTORY_MAPPINGS = [
    (AI_DIR / 'agents', GITHUB_DIR / 'agents', set()),
    (AI_DIR / 'instructions', GITHUB_DIR / 'instructions', {'root.instructions.md', 'repository.instructions.md'}),
    (AI_DIR / 'prompts', GITHUB_DIR / 'prompts', set()),
]

FILE_MAPPINGS = [
    (AI_DIR / 'instructions' / 'root.instructions.md', GITHUB_DIR / 'copilot-instructions.md'),
    (AI_DIR / 'instructions' / 'repository.instructions.md', GITHUB_DIR / 'instructions' / 'copilot-instructions.md'),
]


def sync_directory(source: Path, target: Path, excluded_names: set[str]) -> None:
    if target.exists():
        shutil.rmtree(target)
    shutil.copytree(
        source,
        target,
        ignore=shutil.ignore_patterns(*sorted(excluded_names)) if excluded_names else None,
    )


def sync_file(source: Path, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)


if __name__ == '__main__':
    for source, target, excluded_names in DIRECTORY_MAPPINGS:
        sync_directory(source, target, excluded_names)
    for source, target in FILE_MAPPINGS:
        sync_file(source, target)
    print('Synchronized ai/ into .github/ compatibility adapters.')
