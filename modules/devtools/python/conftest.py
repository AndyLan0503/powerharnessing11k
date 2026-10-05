"""Shared pytest fixtures."""

from __future__ import annotations

{{#if MOD_ARTIFACTS}}
import subprocess
{{/if}}
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
{{#if MOD_ARTIFACTS}}


@pytest.fixture(scope="session")
def verified_artifacts() -> Path:
    """Repo root, once local data/models match artifacts.lock; otherwise skip.

    Use it in tests that need real artifacts. They then run on any machine
    that has the recorded files and skip cleanly (e.g. in CI) on others.
    """
    result = subprocess.run(
        [str(ROOT / "scripts" / "artifacts.sh"), "verify"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        pytest.skip("local artifacts missing or changed:\n" + result.stdout[-500:])
    return ROOT
{{/if}}
{{#unless MOD_ARTIFACTS}}


@pytest.fixture(scope="session")
def repo_root() -> Path:
    return ROOT
{{/if}}
