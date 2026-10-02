"""Verify the configured Hypridle lock hook in disposable Sim, without sleeping."""

import json
import os
import subprocess
import sys
import time

check, *wrapper = sys.argv[1:]
assert wrapper, "Sim desktop-user wrapper required"


def run(*args):
    return subprocess.check_output([*wrapper, *args], text=True, timeout=20).strip()


def parsed(text):
    try:
        return json.loads(text)
    except ValueError as error:
        raise AssertionError("Invalid compositor/session response") from error


def wait_for(predicate):
    end = time.monotonic() + 10
    while time.monotonic() < end:
        if predicate():
            return
        time.sleep(0.1)
    raise AssertionError("Timed out waiting for the native lock hook")


assert run("hostname") == "sim"
run("hyprctl", "eval", 'assert(require("generated.host").name == "sim")')
assert not parsed(run("hyprctl", "-j", "locked"))["locked"]
sessions = parsed(run("loginctl", "list-sessions", "--json=short"))
session = next(
    s["session"] for s in sessions if s["uid"] == 1000 and s["tty"] == "tty1"
)
unit = f"session-lock-test-{os.getpid()}"
try:
    run(
        "systemd-run",
        "--user",
        "--collect",
        "--unit=" + unit,
        "--setenv=XDG_SESSION_ID=" + session,
        check + "/kit/bin/hypridle",
        "-c",
        check + "/kit/hypridle.conf",
    )
    wait_for(
        lambda: (
            "inhibiting until the wayland session gets locked"
            in run("journalctl", "--user", "-u", unit, "--no-pager")
        )
    )
    run("loginctl", "lock-session", session)
    wait_for(lambda: parsed(run("hyprctl", "-j", "locked"))["locked"])
    # Sim only. The native Hyprlock unlock signal ends this isolated check.
    run("pkill", "-USR1", "-u", "1000", "-x", "hyprlock")
    wait_for(lambda: not parsed(run("hyprctl", "-j", "locked"))["locked"])
    print(
        "Native Hypridle lock-notify inhibition, logind lock hook and Hyprlock: passed"
    )
finally:
    if parsed(run("hyprctl", "-j", "locked"))["locked"]:
        run("pkill", "-USR1", "-u", "1000", "-x", "hyprlock")
    run("systemctl", "--user", "stop", unit)
