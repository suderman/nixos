#!/usr/bin/env python3
"""Test prepared themes through a command wrapper for Sim's desktop user.

Usage: python3 test-runtime.py /path/to/sim-user-command-wrapper
The wrapper forwards arbitrary command arguments into Sim, not the live host.
"""

import json
import os
import subprocess
import sys
import time

wrapper = sys.argv[1:]
if not wrapper:
    raise SystemExit("Sim user-command wrapper required")


def run(*args):
    return subprocess.check_output([*wrapper, *args], text=True, timeout=20)


def ctl(*args):
    return run("hyprctl", *args)


def query(name):
    return json.loads(ctl("-j", name))


def wait_for(predicate):
    end = time.monotonic() + 10
    while time.monotonic() < end:
        if predicate():
            return
        time.sleep(0.2)
    raise AssertionError("Timed out waiting for appearance")


assert run("hostname").strip() == "sim", "Runtime tests only run on Sim"
ctl("eval", 'assert(require("generated.host").name == "sim")')
assert not query("locked")["locked"]
original = run("desktop-theme", "get").strip()
system = run("readlink", "-f", "/run/current-system").strip()
binds = len(query("binds"))
name = f"ThemeRuntime{os.getpid()}"
socket = f"unix:/run/user/1000/theme-runtime-{os.getpid()}"
notifications = json.loads(run("notification-mode", "status"))["class"]


def colors():
    result = run("kitty", "@", "--to", socket, "get-colors")
    return dict(line.split() for line in result.splitlines())


try:
    run("desktop-theme", "light")
    ctl(
        "dispatch",
        f'hl.dsp.exec_cmd("kitty --class {name} --listen-on {socket} '
        '--override allow_remote_control=socket-only sleep 10000")',
    )
    wait_for(lambda: any(w["class"] == name for w in query("clients")))
    pid = next(w["pid"] for w in query("clients") if w["class"] == name)
    # The first frame must use the selected mode, before any portal event.
    assert colors()["background"] == "#eff1f5"
    for mode, background, accent, portal in [
        ("dark", "#1e1e2e", "89b4fa", "1"),
        ("light", "#eff1f5", "1e66f5", "2"),
        ("dark", "#1e1e2e", "89b4fa", "1"),
    ]:
        run("desktop-theme", mode)
        wait_for(lambda background=background: colors()["background"] == background)
        assert accent in ctl("getoption", "general:col.active_border")
        preference = run(
            "gdbus",
            "call",
            "--session",
            "--dest",
            "org.freedesktop.portal.Desktop",
            "--object-path",
            "/org/freedesktop/portal/desktop",
            "--method",
            "org.freedesktop.portal.Settings.ReadOne",
            "org.freedesktop.appearance",
            "color-scheme",
        )
        assert f"uint32 {portal}" in preference
        theme = run("rofi", "-dump-theme")
        rgba = "239, 241, 245" if mode == "light" else "30, 30, 46"
        assert any("bg0:" in line and rgba in line for line in theme.splitlines())
        # A palette variable alone is not enough: static target selectors can
        # override the window and keep the actual popup dark.
        window_style = theme.split("window {", 1)[1].split("}", 1)[0]
        assert "var(bg0)" in window_style
        assert "normal-text:" not in theme
        assert next(w["pid"] for w in query("clients") if w["class"] == name) == pid
        assert len(query("binds")) == binds
        ctl("reload")
        assert not any(query("configerrors"))
        assert accent in ctl("getoption", "general:col.active_border")
    run("notification-mode", "toggle")
    changed = json.loads(run("notification-mode", "status"))["class"]
    assert changed != notifications
    run("desktop-theme", "apply")
    assert json.loads(run("notification-mode", "status"))["class"] == changed
    run("notification-mode", "toggle")
    assert run("readlink", "-f", "/run/current-system").strip() == system
    reference = run("desktop-shortcuts", "--list")
    assert "Toggle light/dark appearance" in reference and "\tkeyd\t" in reference
    print(
        "Sim theme events, Kitty startup/live colors, Rofi, reloads, DND and unchanged system: passed"
    )
finally:
    run("desktop-theme", original)
    if json.loads(run("notification-mode", "status"))["class"] != notifications:
        run("notification-mode", "toggle")
    for window in query("clients"):
        if window["class"] == name:
            ctl(
                "dispatch",
                f'hl.dsp.window.close({{ window = "address:{window["address"]}" }})',
            )
