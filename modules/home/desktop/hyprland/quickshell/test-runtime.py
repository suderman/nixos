"""Test rendered popup bindings in disposable Sim, using synthetic status data."""

import argparse
import json
import subprocess
import time
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--static", action="store_true")
parser.add_argument(
    "--screenshots", help="Guest directory for optional rendered evidence"
)
parser.add_argument(
    "--grim", default="grim", help="Guest grim executable for screenshots"
)
parser.add_argument("config")
parser.add_argument("package")
parser.add_argument("assets")
parser.add_argument("wrapper", nargs=argparse.REMAINDER)
args = parser.parse_args()
assert args.wrapper, "Sim user-command wrapper required"


def run(*command):
    return subprocess.check_output([*args.wrapper, *command], text=True, timeout=20)


def decode(value):
    try:
        return json.loads(value)
    except json.JSONDecodeError as error:
        raise AssertionError("Invalid JSON from Sim probe") from error


assert run("hostname").strip() == "sim", "Runtime tests only run on Sim"
run("hyprctl", "eval", 'assert(require("generated.host").name == "sim")')
assert not decode(run("hyprctl", "-j", "locked"))["locked"]
original = run("desktop-theme", "get").strip()
system = run("readlink", "-f", "/run/current-system").strip()
directory = run(
    "python3",
    "-c",
    "import tempfile; print(tempfile.mkdtemp(prefix='quickshell-theme-probe.'))",
).strip()
unit = "quickshell-theme-" + Path(directory).name
qs = args.package + "/bin/qs"
setup = r"""
import json
from pathlib import Path
import re
import sys
source, target = map(Path, sys.argv[1:])
fixtures = {
    "Herdr": {"ok": True, "class": "idle", "counts": {}, "agents": []},
    "MiniMaxQuota": {"ok": True, "status": "normal", "title": "MiniMax quota", "interval": {"used": 37, "total": 100, "remaining": 63, "percent": 37}, "weekly": {"used": 51, "total": 100, "remaining": 49, "percent": 51}},
    "CodexLb": {"ok": True, "status": "ok", "title": "codex-lb", "accounts": [], "recentLogs": []},
}
for name, data in fixtures.items():
    text = (source / (name + ".qml")).read_text()
    command = ["python3", "-c", "print(" + repr(json.dumps(data)) + ")"]
    text, count = re.subn(r'(id: fetch\s+command: )[^\n]+', lambda m: m[1] + json.dumps(command), text)
    assert count == 1, "Fixture must replace only the read-only fetch command"
    (target / (name + ".qml")).write_text(text)
(target / "Theme.qml").write_text((source / "Theme.qml").read_text())
"""


def ipc(method, *values):
    return run(qs, "ipc", "-p", directory, "call", "theme-test", method, *values)


def snapshot():
    return decode(ipc("snapshot"))


def wait_for(predicate):
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        try:
            if predicate():
                return
        except subprocess.CalledProcessError:
            pass  # The IPC endpoint appears after QML finishes loading.
        time.sleep(0.1)
    raise AssertionError(run("journalctl", "--user", "-u", unit, "--no-pager"))


def expect(mode):
    palette = args.assets if args.static else args.assets + "/" + mode + "/palette.json"
    expected = decode(
        run(
            "python3",
            "-c",
            "from pathlib import Path; import sys; print(Path(sys.argv[1]).read_text())",
            palette,
        )
    )
    observed = snapshot()
    light = not args.static and mode == "light"
    text = {
        "heading": expected["base05" if light else "base07"],
        "detail": expected["base05" if light else "base06"],
        "muted": expected["base05" if light else "base04"],
        "selected": "#ffffff" if light else expected["base00"],
    }
    return (
        observed["colors"] == expected
        and observed["text"] == text
        and all(
            popup["background"] == expected["base00"]
            and popup["foreground"] == expected["base05"]
            and popup["accent"] == expected["base0D"]
            for popup in observed["popups"]
        )
    )


try:
    run("python3", "-c", setup, args.config, directory)
    run(
        "python3",
        "-c",
        "from pathlib import Path; import sys; Path(sys.argv[1]).write_text(sys.argv[2])",
        directory + "/shell.qml",
        Path(__file__).with_name("test-shell.qml").read_text(),
    )
    run("desktop-theme", "dark")
    run(
        "systemd-run",
        "--user",
        "--collect",
        "--property=Type=exec",
        "--unit=" + unit,
        qs,
        "-p",
        directory,
    )
    wait_for(lambda: expect("dark"))
    pid = run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit).strip()
    assert pid != "0"
    ipc("openPinned")
    wait_for(
        lambda: all(
            p["open"] and p["pinned"] and p["data"]["ok"] for p in snapshot()["popups"]
        )
    )
    before = snapshot()
    for mode in ["light", "dark", "light", "dark", "light"]:
        run("desktop-theme", mode)
        wait_for(lambda mode=mode: expect(mode))
        observed = snapshot()
        assert all(p["open"] and p["pinned"] for p in observed["popups"])
        assert [p["data"] for p in observed["popups"]] == [
            p["data"] for p in before["popups"]
        ]
        assert observed["actionMessage"] == "Probe in progress"
        assert (
            run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit).strip()
            == pid
        )
    run("hyprctl", "reload")
    wait_for(lambda: expect("light"))
    assert (
        run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit).strip()
        == pid
    )
    if args.screenshots:
        run("mkdir", "-p", args.screenshots)
        for mode in ["dark", "light"]:
            run("desktop-theme", mode)
            wait_for(lambda mode=mode: expect(mode))
            for name in ["herdr", "mini", "codex"]:
                ipc("showOnly", name)
                time.sleep(0.5)
                run(args.grim, args.screenshots + "/" + mode + "-" + name + ".png")
    assert run("readlink", "-f", "/run/current-system").strip() == system
    assert not any(decode(run("hyprctl", "-j", "configerrors")))
    kind = "static" if args.static else "dynamic"
    print(f"Sim {kind} popup colors, pinned state, data, reload and stable PID: passed")
finally:
    run("systemctl", "--user", "stop", unit)
    run("desktop-theme", original)
    run("rm", "-rf", directory)
