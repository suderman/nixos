"""Exercise brightness and the real OSD with fake backlight hardware in Sim."""

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

check, package, *wrapper = sys.argv[1:]
assert wrapper, "Sim desktop-user wrapper required"


def run(*args):
    return subprocess.check_output([*wrapper, *args], text=True, timeout=20)


def wait_for(predicate):
    for _ in range(100):
        if predicate():
            return
        time.sleep(0.1)
    raise AssertionError("Brightness did not converge: " + ipc("brightnessSnapshot"))


assert run("hostname").strip() == "sim"
run("hyprctl", "eval", 'assert(require("generated.host").name == "sim")')
assert not json.loads(run("hyprctl", "-j", "locked"))["locked"]
system = run("readlink", "-f", "/run/current-system")
mode = run("desktop-theme", "get").strip()
fixture = run(
    "python3",
    "-c",
    'import tempfile; print(tempfile.mkdtemp(prefix="brightness-runtime-"))',
).strip()
qs = package + "/bin/qs"
unit = "brightness-runtime-" + str(os.getpid())
named = "/home/jon/.config/quickshell/hyprland"
registered = False
statefile = fixture + "/state.json"
initial = {"percentage": 45, "available": True, "fail": False}
run(
    "cp",
    *[
        check + "/cog/config/" + file
        for file in [
            "Theme.qml",
            "QuickSettings.qml",
            "AudioControls.qml",
            "BluetoothControls.qml",
            "BrightnessControls.qml",
            "NetworkControls.qml",
            "MediaOsd.qml",
        ]
    ],
    fixture,
)
shell = Path(__file__).with_name("test-settings-shell.qml").read_text()
shell = shell.replace(
    "  QuickSettings { id: settings }",
    "  QuickSettings { id: settings }\n  MediaOsd { id: osd }",
)
shell = shell.replace(
    '    target: "settings-test"',
    '    target: "settings-test"\n    function osdSnapshot(): string { return JSON.stringify({open: osd.open, progress: osd.progress, image: osd.image}); }',
)


def write(path, content):
    run(
        "python3",
        "-c",
        "from pathlib import Path; import sys; Path(sys.argv[1]).write_text(sys.argv[2])",
        path,
        content,
    )


write(fixture + "/shell.qml", shell)
write(
    fixture + "/test-backlight.py",
    Path(__file__).with_name("test-backlight.py").read_text(),
)
run(
    "python3",
    fixture + "/test-backlight.py",
    "--install",
    fixture + "/bin",
    check + "/cog/bin/mediactl",
)
write(statefile, json.dumps(initial))


def ipc(method, *args):
    return run(qs, "ipc", "-p", named, "call", "settings-test", method, *args)


def state():
    return json.loads(ipc("brightnessSnapshot"))


def point():
    p = json.loads(ipc("audioPoint", "backlightBrightness"))
    layer = next(
        layer
        for monitor in json.loads(run("hyprctl", "-j", "layers")).values()
        for level in monitor["levels"].values()
        for layer in level
        if layer["namespace"] == "quickshell-quick-settings"
    )
    p["x"] += layer["x"]
    p["y"] += layer["y"]
    return p


def move(x, y):
    run(
        "ydotool",
        "mousemove",
        "--absolute",
        "-x",
        str(round(x / 2)),
        "-y",
        str(round(y / 2)),
    )
    pos = json.loads(run("hyprctl", "-j", "cursorpos"))
    assert abs(pos["x"] - x) < 3 and abs(pos["y"] - y) < 3


def control(*args):
    run(
        "env",
        "BACKLIGHT_TEST_PATH=" + fixture + "/bin",
        "BACKLIGHT_STATE=" + statefile,
        fixture + "/bin/mediactl",
        *args,
    )


def matching_osd(value):
    osd = json.loads(ipc("osdSnapshot"))
    return (
        osd["open"]
        and osd["image"].startswith("brightness_")
        and abs(osd["progress"] - value / 100) < 0.001
    )


try:
    run(
        "python3",
        "-c",
        "from pathlib import Path; import sys; p=Path(sys.argv[1]); p.parent.mkdir(parents=True, exist_ok=True); assert not p.exists(); p.symlink_to(sys.argv[2])",
        named,
        fixture,
    )
    registered = True
    run(
        "systemd-run",
        "--user",
        "--collect",
        "--unit=" + unit,
        "--setenv=BACKLIGHT_TEST_PATH=" + fixture + "/bin",
        "--setenv=BACKLIGHT_STATE=" + statefile,
        "--setenv=PATH=" + fixture + "/bin:" + run("printenv", "PATH").strip(),
        qs,
        "-p",
        named,
    )
    time.sleep(1)
    run(qs, "ipc", "-p", named, "call", "quick-settings", "toggle")
    wait_for(lambda: state()["percentage"] == 45)
    pid = run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit)
    p = point()
    left = p["x"] - p["width"] / 2 + 8
    right = p["x"] + p["width"] / 2 - 8
    move(left, p["y"])
    run("ydotool", "click", "0xC0")
    wait_for(lambda: state()["percentage"] == 1)
    assert matching_osd(1)
    run("ydotool", "click", "0x40")
    for fraction in [0.1, 0.3, 0.6, 0.9, 1.0]:
        move(left + (right - left) * fraction, p["y"])
    run("ydotool", "click", "0x80")
    wait_for(lambda: state()["percentage"] == 100)
    assert matching_osd(100)
    run("ydotool", "key", "105:1", "105:0")
    wait_for(lambda: state()["percentage"] == 99)
    control("dark")
    wait_for(lambda: state()["percentage"] == 94)
    assert matching_osd(94)
    control("light")
    wait_for(lambda: state()["percentage"] == 99)
    assert matching_osd(99)
    write(statefile, json.dumps(initial | {"percentage": 30}))
    wait_for(lambda: state()["percentage"] == 30)
    write(statefile, json.dumps(initial | {"percentage": 30, "fail": True}))
    move(right, p["y"])
    run("ydotool", "click", "0xC0")
    wait_for(lambda: state()["failed"])
    assert state()["percentage"] == 30 and state()["open"]
    write(statefile, json.dumps(initial))
    move(left + (right - left) * 0.5, p["y"])
    run("ydotool", "click", "0xC0")
    wait_for(lambda: not state()["failed"] and state()["percentage"] in [50, 51])
    write(statefile, json.dumps(initial | {"available": False}))
    wait_for(lambda: not state()["available"])
    assert not json.loads(ipc("audioPoint", "backlightBrightness"))["enabled"]
    write(statefile, json.dumps(initial))
    wait_for(lambda: state()["percentage"] == 45)
    for theme in ["light", "dark"]:
        run("desktop-theme", theme)
        time.sleep(0.3)
        if os.environ.get("QUICK_SETTINGS_SCREENSHOTS"):
            run(
                os.environ["QUICK_SETTINGS_GRIM"],
                os.environ["QUICK_SETTINGS_SCREENSHOTS"]
                + "/brightness-"
                + theme
                + ".png",
            )
    run(qs, "ipc", "-p", named, "call", "quick-settings", "hide")
    time.sleep(0.6)
    calls = run("wc", "-l", fixture + "/state.calls").split()[0]
    time.sleep(1.1)
    assert run("wc", "-l", fixture + "/state.calls").split()[0] == calls
    assert run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit) == pid
    assert run("readlink", "-f", "/run/current-system") == system
    journal = run("journalctl", "--user", "-u", unit, "--no-pager")
    assert not re.search(
        r"TypeError|ReferenceError|Cannot read property|failed to load",
        journal,
        re.IGNORECASE,
    )
    print(
        "Native backlight drag/keyboard, vendor key steps and OSD sync, external updates, failures, removal/reappearance and closed-panel polling stop: passed"
    )
finally:
    run("systemctl", "--user", "stop", unit)
    if registered:
        run("rm", named)
    run("desktop-theme", mode)
    run("rm", "-rf", fixture)
