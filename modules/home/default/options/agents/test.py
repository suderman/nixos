#!/usr/bin/env python3
"""Check checkout installation and mutable command dispatch in disposable homes."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile

checkout, command, stylix, herdr = sys.argv[1:]


def run(args, env, expected=0):
    result = subprocess.run(args, env=env, text=True, capture_output=True, check=False)
    assert result.returncode == expected, (
        args,
        result.returncode,
        result.stdout,
        result.stderr,
    )
    return result.stdout


with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    home = root / "home"
    home.mkdir()
    env = {
        "HOME": str(home),
        "PATH": os.environ["PATH"],
        "GIT_CONFIG_NOSYSTEM": "1",
        "GIT_TERMINAL_PROMPT": "0",
    }
    source = root / "source"
    source.mkdir()
    (source / "agents").write_text('import sys\nprint("original", *sys.argv[1:])\n')
    run(["git", "init", "-q", str(source)], env)
    run(["git", "-C", str(source), "add", "agents"], env)
    run(
        [
            "git",
            "-C",
            str(source),
            "-c",
            "user.name=Fixture",
            "-c",
            "user.email=fixture@example.invalid",
            "commit",
            "-qm",
            "fixture",
        ],
        env,
    )
    online = env | {
        "GIT_CONFIG_COUNT": "1",
        "GIT_CONFIG_KEY_0": f"url.{source}.insteadOf",
        "GIT_CONFIG_VALUE_0": "https://github.com/suderman/agents.git",
    }
    offline = online | {"GIT_CONFIG_KEY_0": f"url.{root / 'unavailable'}.insteadOf"}

    # Missing checkout is reported by the CLI, never installed inline.
    run([command, "doctor"], offline, expected=1)
    assert not (home / ".agents").exists()

    # A failed offline clone can retry into an empty persisted directory.
    repository = home / ".agents"
    repository.mkdir()
    run([checkout], offline, expected=128)
    assert not list(repository.iterdir())
    run([checkout], online)
    assert run([command, "skill", "list"], offline) == "original skill list\n"

    # The command reads mutable source on each call, not a store snapshot.
    (repository / "agents").write_text('import sys\nprint("changed", *sys.argv[1:])\n')
    (repository / "skills.lock").write_text(
        "malformed lock, irrelevant to installation\n"
    )
    before = subprocess.check_output(
        ["git", "-C", str(repository), "status", "--porcelain"], env=env
    )
    run([checkout], offline)
    after = subprocess.check_output(
        ["git", "-C", str(repository), "status", "--porcelain"], env=env
    )
    assert before == after
    assert run([command, "apply"], offline) == "changed apply\n"

    # Preserve non-checkout user content rather than replacing it.
    blocked_home = root / "blocked"
    blocked = blocked_home / ".agents"
    blocked.mkdir(parents=True)
    (blocked / "keep").write_text("user content\n")
    run([checkout], offline | {"HOME": str(blocked_home)}, expected=78)
    assert list(blocked.iterdir()) == [blocked / "keep"]
    assert (blocked / "keep").read_text() == "user content\n"

    # Machine-owned Pi integrations do not need checkout, profile, or network.
    isolated = root / "integrations"
    isolated.mkdir()
    pi = isolated / ".pi" / "agent"
    integration_env = env | {
        "HOME": str(isolated),
        "PI_CODING_AGENT_DIR": str(pi),
        "DRY_RUN_CMD": "",
    }
    for activation in (stylix, herdr):
        script = Path(activation).read_text().replace("/home/jon", str(isolated))
        run(["bash", "-eu", "-c", script], integration_env)
    assert (pi / "themes" / "stylix.json").is_file()
    assert (pi / "extensions" / "herdr-agent-state.ts").is_file()
    assert not (isolated / ".agents").exists()
    assert not (isolated / "profile").exists()

print("Agents installation, mutable dispatch, and offline Pi integrations passed")
