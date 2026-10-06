"""Check path policy and state migration in disposable homes."""

import importlib.util
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "migration", Path(__file__).with_name("migrate-state.py")
)
assert spec is not None and spec.loader is not None
migration = importlib.util.module_from_spec(spec)
spec.loader.exec_module(migration)


def snapshot(home):
    result = {}
    for path in sorted(home.rglob("*")):
        info = path.lstat()
        value = (
            str(path.readlink())
            if path.is_symlink()
            else path.read_bytes()
            if path.is_file()
            else None
        )
        result[str(path.relative_to(home))] = (
            value,
            info.st_mode,
            info.st_ino,
            info.st_mtime_ns,
        )
    return result


def write(home, name, content):
    path = home / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    return path


with tempfile.TemporaryDirectory() as directory:
    home = Path(directory)
    source = write(
        home, ".local/state/pi/sessions/--project--/session.jsonl", "history\n"
    )
    write(home, ".local/state/pi/pi-lens/projects/project/cache.json", "{}\n")
    write(home, ".local/state/pi/fff/frecency/data.mdb", "database\n")
    write(home, ".config/pi/pi-lens.json", '{"tier":"custom"}\n')
    tool = home / ".local/state/pi/pi-lens/tools/server"
    tool.parent.mkdir()
    tool.symlink_to("/nix/store/fixture-server")
    source.chmod(0o600)
    before = snapshot(home)
    assert migration.migrate(home) > 0
    assert snapshot(home) == before
    assert migration.migrate(home, apply=True) > 0
    target = home / ".pi/agent/sessions/--project--/session.jsonl"
    assert target.read_bytes() == source.read_bytes()
    assert target.stat().st_mode == source.stat().st_mode
    assert (home / ".pi-lens/config.json").read_text() == '{"tier":"custom"}\n'
    assert (home / ".pi-lens/tools/server").readlink() == Path(
        "/nix/store/fixture-server"
    )
    after = snapshot(home)
    assert migration.migrate(home, apply=True) == 0
    assert snapshot(home) == after
    assert all(after[path] == value for path, value in before.items())

    # Existing links to the legacy source become independent native copies.
    target.unlink()
    target.symlink_to(source)
    assert migration.migrate(home, apply=True) == 1
    assert target.is_file() and not target.is_symlink()
    assert target.read_bytes() == source.read_bytes()

    # Conflict preflight must finish before any copy, including other mappings.
    target.write_text("different history\n")
    write(home, ".local/state/pi/pi-lens/new.json", "new data\n")
    before = snapshot(home)
    try:
        migration.migrate(home, apply=True)
    except ValueError as error:
        assert "Conflicting destination" in str(error)
    else:
        raise AssertionError("conflict accepted")
    assert snapshot(home) == before

with tempfile.TemporaryDirectory() as directory:
    home = Path(directory)
    assert migration.migrate(home, apply=True) == 0
    write(home, ".local/state/pi/pi-lens/cache.json", "{}\n")
    outside = home / "outside"
    outside.mkdir()
    (home / ".pi-lens").symlink_to(outside)
    before = snapshot(home)
    try:
        migration.migrate(home, apply=True)
    except ValueError:
        pass
    else:
        raise AssertionError("destination symlink accepted")
    assert snapshot(home) == before

with tempfile.TemporaryDirectory() as directory:
    home = Path(directory)
    legacy = write(home, ".local/state/pi/fff/frecency/data.mdb", "legacy database\n")
    native = write(home, ".pi/agent/fff/frecency/data.mdb", "native database\n")
    write(home, ".local/state/pi/sessions/--project--/session.jsonl", "history\n")
    before = snapshot(home)
    try:
        migration.migrate(home, apply=True)
    except ValueError:
        pass
    else:
        raise AssertionError("conflicting FFF databases accepted")
    assert snapshot(home) == before
    assert migration.migrate(home, apply=True, skip_fff=True) > 0
    assert legacy.read_text() == "legacy database\n"
    assert native.read_text() == "native database\n"
    assert migration.migrate(home, apply=True, skip_fff=True) == 0

if len(sys.argv) > 1:
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

print("Pi native path policy and non-destructive state migration passed")
