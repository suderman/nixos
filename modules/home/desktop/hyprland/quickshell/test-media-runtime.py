"""Run native media overlay tests through a Sim desktop-user command wrapper.

Usage: test-media-runtime.py COMPILED_CONFIG QUICKSHELL_PACKAGE WRAPPER [ARGS...]
"""

import json
import os
import subprocess
import sys
import time
from pathlib import Path

config, package, *wrapper = sys.argv[1:]
assert wrapper, "Sim command wrapper required"


def run(*args):
    return subprocess.check_output([*wrapper, *args], text=True, timeout=20)


def parsed(text):
    try:
        return json.loads(text)
    except ValueError as error:
        raise AssertionError("Invalid native media snapshot") from error


assert run("hostname").strip() == "sim"
run("hyprctl", "eval", 'assert(require("generated.host").name == "sim")')
assert not parsed(run("hyprctl", "-j", "locked"))["locked"]
original = run("desktop-theme", "get").strip()
system = run("readlink", "-f", "/run/current-system").strip()
fixture = run(
    "python3", "-c", 'import tempfile; print(tempfile.mkdtemp(prefix="media-runtime-"))'
).strip()
unit = f"media-runtime-{os.getpid()}"
monitor = f"MediaTest-{os.getpid()}"
created_monitor = False
qs = package + "/bin/qs"
run("cp", config + "/Theme.qml", config + "/MediaOsd.qml", fixture)
run(
    "python3",
    "-c",
    "from pathlib import Path; import sys; Path(sys.argv[1]).write_text(sys.argv[2])",
    fixture + "/shell.qml",
    Path(__file__).with_name("test-media-shell.qml").read_text(),
)


def ipc(target, method, *args):
    return run(qs, "ipc", "-p", fixture, "call", target, method, *map(str, args))


def snapshot():
    return parsed(ipc("media-test", "snapshot"))


def display(image, progress=0.5, monitor=-1):
    ipc("media-osd", "display", image, progress, monitor)


try:
    run("systemd-run", "--user", "--collect", "--unit=" + unit, qs, "-p", fixture)
    for _ in range(30):
        ready = subprocess.run(
            [*wrapper, qs, "ipc", "-p", fixture, "call", "media-test", "snapshot"],
            capture_output=True,
        )
        if ready.returncode == 0:
            break
        time.sleep(0.1)
    else:
        raise AssertionError(run("journalctl", "--user", "-u", unit, "--no-pager"))
    pid = run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit).strip()
    active = parsed(run("hyprctl", "-j", "activewindow"))
    ipc("media-test", "lifetime", 10000)
    for mode, image, background in [
        ("dark", "volume_medium", "#1e1e2e"),
        ("light", "mic_muted", "#eff1f5"),
        ("dark", "brightness_high", "#1e1e2e"),
    ]:
        run("desktop-theme", mode)
        display(image, 1.5)
        state = snapshot()
        assert state["open"] and state["image"] == image and state["progress"] == 1
        assert state["background"] == background and state["screen"]
        if pictures := os.environ.get("MEDIA_OSD_SCREENSHOTS"):
            run("mkdir", "-p", pictures)
            time.sleep(0.3)
            run(
                os.environ.get("MEDIA_OSD_GRIM", "grim"),
                pictures + "/" + mode + "-" + image + ".png",
            )
        assert parsed(run("hyprctl", "-j", "activewindow")) == active
        assert (
            run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit).strip()
            == pid
        )
    saved = snapshot()
    display("invalid", 0.2)
    assert snapshot() == saved
    display("volume_low", 0.2, 999)
    assert snapshot() == saved
    display("volume_low", 0.2, 0)
    assert snapshot()["screen"] == snapshot()["screens"][0]
    run("hyprctl", "output", "create", "headless", monitor)
    created_monitor = True
    run("hyprctl", "dispatch", f'hl.dsp.focus({{ monitor = "{monitor}" }})')
    time.sleep(0.5)
    display("brightness_medium")
    assert snapshot()["screen"] == monitor, "Default OSD must follow focused monitor"
    ipc("media-test", "setLocked", "true")
    time.sleep(0.5)
    assert snapshot()["secure"] and parsed(run("hyprctl", "-j", "locked"))["locked"]
    display("volume_medium")
    assert snapshot()["secure"], "Media feedback must not unlock the session"
    if pictures := os.environ.get("MEDIA_OSD_SCREENSHOTS"):
        time.sleep(0.3)
        run(
            os.environ.get("MEDIA_OSD_GRIM", "grim"),
            pictures + "/locked.png",
        )
    ipc("media-test", "setLocked", "false")
    time.sleep(0.3)
    assert not parsed(run("hyprctl", "-j", "locked"))["locked"]
    ipc("media-test", "lifetime", 1000)
    display("volume_medium")
    time.sleep(0.6)
    display("volume_medium")
    time.sleep(0.6)
    assert snapshot()["open"], "Repeated key should restart dismissal"
    time.sleep(0.7)
    assert not snapshot()["open"]
    assert run("readlink", "-f", "/run/current-system").strip() == system
    print(
        "Native OSD modes, palette, gauge clamp, focus, monitor, repeat timer and PID: passed"
    )
finally:
    ipc("media-test", "setLocked", "false")
    run("systemctl", "--user", "stop", unit)
    if created_monitor:
        run("hyprctl", "output", "remove", monitor)
    run("desktop-theme", original)
    run("rm", "-rf", fixture)
