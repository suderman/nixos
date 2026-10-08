"""Check the Pi wrapper's path policy in a disposable home."""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


def write(home, name, content):
    path = home / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    return path


wrapper, python = sys.argv[1:]
overrides = [
    "PI_CODING_AGENT_DIR",
    "PI_CODING_AGENT_SESSION_DIR",
    "PI_LENS_CONFIG_PATH",
    "PI_LENS_HOME",
    "PILENS_DATA_DIR",
    "FFF_FRECENCY_DB",
    "FFF_HISTORY_DB",
]
with tempfile.TemporaryDirectory() as directory:
    home = Path(directory)
    probe = home / "probe"
    probe.write_text(
        f'#!{python}\nimport json, os, sys\nprint(json.dumps({{"env":dict(os.environ),"args":sys.argv[1:]}}))\n'
    )
    probe.chmod(0o700)
    native = ".pi/agent"
    write(home, f"{native}/.env", "FIXTURE_KEY=first\n")
    write(home, f"{native}/.env.local", "FIXTURE_KEY=local\n")
    manifest = write(
        home,
        f"{native}/npm/node_modules/@pi-vault/pi-dcp/package.json",
        '{"dependencies":{"typebox":"old"}}\n',
    )
    env = {"HOME": str(home), "PATH": os.environ["PATH"], "PI_BIN": str(probe)}

    def invoke(environment):
        result = subprocess.run(
            [wrapper, "--resume"],
            env=environment,
            capture_output=True,
            text=True,
            check=True,
        )
        return json.loads(result.stdout)

    result = invoke(env)
    assert result["args"] == ["--resume"]
    assert result["env"]["FIXTURE_KEY"] == "local"
    assert all(key not in result["env"] for key in overrides)
    assert json.loads(manifest.read_text()) == {
        "dependencies": {},
        "peerDependencies": {"typebox": "*"},
    }
    saved = manifest.stat().st_mtime_ns
    invoke(env)
    assert manifest.stat().st_mtime_ns == saved
    explicit = env | {key: str(home / "custom" / key) for key in overrides}
    write(home, "custom/PI_CODING_AGENT_DIR/.env", "FIXTURE_KEY=custom\n")
    result = invoke(explicit)
    assert all(result["env"][key] == explicit[key] for key in overrides)
    assert result["env"]["FIXTURE_KEY"] == "custom"

print("Pi native path policy passed")
