"""Test quick settings in Sim through a desktop-user command wrapper."""

import json
import os
import re
import socket
import subprocess
import sys
import time
from pathlib import Path

config, package, monitor, *wrapper = sys.argv[1:]
assert wrapper, "Sim wrapper required"


def run(*args):
    return subprocess.check_output([*wrapper, *args], text=True, timeout=20)


def parsed(text):
    try:
        return json.loads(text)
    except ValueError as error:
        raise AssertionError("Invalid settings snapshot") from error


def wait_for(predicate):
    end = time.monotonic() + 10
    while time.monotonic() < end:
        if predicate():
            return
        time.sleep(0.1)
    raise AssertionError("Timed out waiting for quick settings")


def move(x, y):
    # Sim's virtual pointer scales these absolute coordinates by two.
    run("ydotool", "mousemove", "--absolute", "-x", str(x // 2), "-y", str(y // 2))
    pos = parsed(run("hyprctl", "-j", "cursorpos"))
    assert abs(pos["x"] - x) < 3 and abs(pos["y"] - y) < 3


def hmp(command):
    with socket.socket(socket.AF_UNIX) as connection:
        connection.settimeout(5)
        connection.connect(monitor)
        for outgoing in [None, command]:
            if outgoing:
                connection.sendall((outgoing + "\n").encode())
            data = b""
            while not data.endswith(b"(qemu) "):
                data += connection.recv(4096)


assert run("hostname").strip() == "sim"
run("hyprctl", "eval", 'assert(require("generated.host").name == "sim")')
assert not parsed(run("hyprctl", "-j", "locked"))["locked"]
original = run("desktop-theme", "get").strip()
system = run("readlink", "-f", "/run/current-system").strip()
fixture = run(
    "python3",
    "-c",
    'import tempfile; print(tempfile.mkdtemp(prefix="settings-runtime-"))',
).strip()
qs = package + "/bin/qs"
unit = f"settings-runtime-{os.getpid()}"
run(
    "cp",
    config + "/Theme.qml",
    config + "/QuickSettings.qml",
    config + "/AudioControls.qml",
    config + "/BluetoothControls.qml",
    fixture,
)
run(
    "python3",
    "-c",
    "from pathlib import Path; import sys; Path(sys.argv[1]).write_text(sys.argv[2])",
    fixture + "/shell.qml",
    Path(__file__).with_name("test-settings-shell.qml").read_text(),
)


def ipc(target, method, *args):
    return run(qs, "ipc", "-p", instance, "call", target, method, *args)


def state():
    return parsed(ipc("settings-test", "snapshot"))


created_monitor = False
original_notifications = None
temperature = None
waybar_active = None
bar_unit = unit + "-waybar"
named_config = "/home/jon/.config/quickshell/hyprland"
registered_config = False
instance = fixture
try:
    if os.environ.get("QUICK_SETTINGS_WAYBAR"):
        bar = json.loads(Path(os.environ["QUICK_SETTINGS_WAYBAR"]).read_text())
        assert parsed(run(bar["custom/quick-settings"]["exec"]))["class"] == ""
        print("Waybar status remains valid JSON when Quickshell is unavailable: passed")
        # Named-config IPC must use the same path as the running shell.
        run(
            "python3",
            "-c",
            "from pathlib import Path; import sys; p=Path(sys.argv[1]); p.parent.mkdir(parents=True, exist_ok=True); assert not p.exists(); p.symlink_to(sys.argv[2])",
            named_config,
            fixture,
        )
        registered_config = True
        instance = named_config
    environment = []
    if os.environ.get("QUICK_SETTINGS_GRIM"):
        # Keep the compiled capture commands intact. Substitute only their
        # printscreen owner inside Sim, and take a real compositor screenshot
        # at handoff without starting annotation/recording or reading secrets.
        capture = f"""import json, subprocess, sys
from pathlib import Path
mode = sys.argv[1]
layers = json.loads(subprocess.check_output(['hyprctl', '-j', 'layers']))
visible = any(layer['namespace'] == 'quickshell-quick-settings'
    for monitor in layers.values() for level in monitor['levels'].values()
    for layer in level)
image = Path({fixture!r}) / (mode + '.png')
subprocess.run([{os.environ["QUICK_SETTINGS_GRIM"]!r}, str(image)], check=True)
assert image.read_bytes().startswith(b'\\x89PNG\\r\\n\\x1a\\n')
with Path({(fixture + "/captures")!r}).open('a') as log:
    log.write(json.dumps({{'mode': mode, 'panelVisible': visible}}) + '\\n')
"""
        interpreter = run("bash", "-c", "command -v python3").strip()
        run("mkdir", fixture + "/bin")
        run(
            "python3",
            "-c",
            "from pathlib import Path; import sys; p=Path(sys.argv[1]); p.write_text(sys.argv[2]); p.chmod(0o755)",
            fixture + "/bin/printscreen",
            "#!" + interpreter + "\n" + capture,
        )
        environment = [
            "--setenv=PATH=" + fixture + "/bin:" + run("printenv", "PATH").strip()
        ]
    run(
        "systemd-run",
        "--user",
        "--collect",
        "--unit=" + unit,
        *environment,
        qs,
        "-p",
        instance,
    )
    for _ in range(40):
        ready = subprocess.run(
            [*wrapper, qs, "ipc", "-p", instance, "call", "settings-test", "snapshot"],
            capture_output=True,
            check=False,
        )
        if ready.returncode == 0:
            break
        time.sleep(0.1)
    else:
        raise AssertionError(run("journalctl", "--user", "-u", unit, "--no-pager"))
    pid = run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit)
    ipc("quick-settings", "toggle")
    wait_for(lambda: state()["open"])
    for mode, color in [("light", "#eff1f5"), ("dark", "#1e1e2e")]:
        ipc("settings-test", "activate", mode)
        wait_for(lambda mode=mode: state()["feedback"] == mode.title() + " updated")
        assert (
            state()["open"]
            and state()["mode"] == mode
            and state()["background"] == color
        )
        if os.environ.get("QUICK_SETTINGS_SCREENSHOTS"):
            run(
                os.environ["QUICK_SETTINGS_GRIM"],
                os.environ["QUICK_SETTINGS_SCREENSHOTS"] + "/" + mode + ".png",
            )
    wait_for(lambda: state()["notifications"] in ["normal", "silenced"])
    notifications = state()["notifications"]
    original_notifications = notifications
    for _ in range(2):
        ipc("settings-test", "activate", "notifications")
        wait_for(lambda: state()["feedback"] == "Notifications updated")
        wait_for(lambda previous=notifications: state()["notifications"] != previous)
        notifications = state()["notifications"]
    # Use only the three relevant modules, never production account commands.
    if os.environ.get("QUICK_SETTINGS_WAYBAR"):
        bar = json.loads(Path(os.environ["QUICK_SETTINGS_WAYBAR"]).read_text())
        assert bar["modules-right"][-2:] == ["custom/quick-settings", "custom/power"]
        assert bar["custom/quick-settings"]["signal"] == 11
        assert bar["custom/quick-settings"]["interval"] == "once"
        bar["modules-left"] = []
        bar["modules-center"] = []
        bar["modules-right"] = [
            "custom/notifications",
            "custom/quick-settings",
            "custom/power",
        ]
        bar["custom/notifications"]["interval"] = (
            3600  # Prove signal refresh, not polling.
        )
        bar["custom/quick-settings"]["on-click"] = (
            f"{qs} ipc -p {instance} call quick-settings toggle"
        )
        run(
            "python3",
            "-c",
            "from pathlib import Path; import sys; Path(sys.argv[1]).write_text(sys.argv[2])",
            fixture + "/waybar.json",
            json.dumps(bar),
        )
        run(
            "python3",
            "-c",
            "from pathlib import Path; import sys; Path(sys.argv[1]).write_text(sys.argv[2])",
            fixture + "/waybar.css",
            Path(os.environ["QUICK_SETTINGS_WAYBAR"]).with_suffix(".css").read_text(),
        )
        waybar_active = (
            run(
                "systemctl", "--user", "show", "-p", "ActiveState", "--value", "waybar"
            ).strip()
            == "active"
        )
        run("systemctl", "--user", "stop", "waybar")
        run(
            "systemd-run",
            "--user",
            "--collect",
            "--unit=" + bar_unit,
            "waybar",
            "-c",
            fixture + "/waybar.json",
            "-s",
            fixture + "/waybar.css",
        )
        time.sleep(1)
        assert parsed(run("hyprctl", "-j", "monitors"))[0]["width"] == 1280

        def click(x, y):
            move(x, y)
            run("ydotool", "click", "0xC0")

        def image_hash(region):
            run(
                os.environ["QUICK_SETTINGS_GRIM"],
                "-g",
                region,
                fixture + "/module.png",
            )
            return run("sha256sum", fixture + "/module.png").split()[0]

        def bell():
            return image_hash("1170,0 40x30")

        def cog():
            return image_hash("1207,0 28x30")

        ipc("quick-settings", "hide")
        move(200, 400)
        time.sleep(0.6)
        closed_cog = cog()
        ipc("quick-settings", "toggle")
        time.sleep(0.6)
        assert parsed(ipc("quick-settings", "status"))["class"] == "active"
        assert cog() != closed_cog
        # Enter and leave without clicking. A brief return cancels dismissal.
        move(930, 180)
        run(
            "bash",
            "-c",
            "ydotool mousemove --absolute -x 100 -y 200; sleep 0.1; ydotool mousemove --absolute -x 465 -y 90",
        )
        time.sleep(0.6)
        assert state()["open"]
        move(200, 400)
        wait_for(lambda: not state()["open"])
        wait_for(lambda: cog() == closed_cog)
        assert parsed(ipc("quick-settings", "status"))["class"] == ""
        ipc("quick-settings", "toggle")
        move(930, 180)
        time.sleep(0.6)
        assert state()["open"]
        before = bell()
        notifications = state()["notifications"]
        click(930, 324)  # Native notification button below audio/Bluetooth controls.
        wait_for(lambda: state()["notifications"] != notifications)
        wait_for(lambda: bell() != before)
        ipc("quick-settings", "hide")
        click(1188, 14)  # Native Waybar bell, using its real on-click command.
        run("ydotool", "mousemove", "--absolute", "-x", "100", "-y", "200")
        wait_for(lambda: bell() == before)
        click(1218, 14)  # Padded cog before power must open the same panel.
        wait_for(lambda: state()["open"] and state()["notifications"] == notifications)
        print(
            "Native cog tint/reset, pointer-leave dismissal/cancel, notification sync and signal-only refresh: passed"
        )
    wait_for(lambda: state()["temperature"] is not None)
    temperature = state()["temperature"]
    ipc("settings-test", "activate", "nightlight")
    wait_for(lambda: state()["feedback"] == "Night Light updated")
    wait_for(lambda: state()["temperature"] != temperature)
    run("hyprctl", "hyprsunset", "temperature", str(temperature))
    ipc("settings-test", "activate", "not-a-command")
    assert state()["open"]
    hmp("sendkey esc")
    wait_for(lambda: not state()["open"])
    ipc("quick-settings", "toggle")
    wait_for(lambda: state()["open"])
    # Sim's headless vmmouse does not deliver HMP pointer motion. Use the
    # configured virtual input device, then verify the actual cursor position.
    run("ydotool", "mousemove", "--absolute", "-x", "100", "-y", "200")
    cursor = parsed(run("hyprctl", "-j", "cursorpos"))
    assert cursor["x"] < 800
    run("ydotool", "click", "0xC0")
    wait_for(lambda: not state()["open"])
    ipc("quick-settings", "toggle")
    ipc("settings-test", "failLight")
    ipc("settings-test", "activate", "light")
    wait_for(lambda: state()["feedback"] == "Could not update Light")
    assert state()["open"]
    if os.environ.get("QUICK_SETTINGS_GRIM"):
        for id, mode in [
            ("screenshot", "image"),
            ("recording", "video"),
            ("text", "text"),
            ("qr", "qr"),
            ("color", "color"),
        ]:
            if not state()["open"]:
                ipc("quick-settings", "toggle")
            p = parsed(ipc("settings-test", "audioPoint", "setting-" + id))
            layers = parsed(run("hyprctl", "-j", "layers"))
            layer = next(
                layer
                for monitor in layers.values()
                for level in monitor["levels"].values()
                for layer in level
                if layer["namespace"] == "quickshell-quick-settings"
            )
            move(round(p["x"] + layer["x"]), round(p["y"] + layer["y"]))
            run("ydotool", "click", "0xC0")
            wait_for(lambda: not state()["open"])
            wait_for(
                lambda mode=mode: (
                    mode
                    in run(
                        "python3",
                        "-c",
                        "from pathlib import Path; import sys; p=Path(sys.argv[1]); print(p.read_text() if p.exists() else '')",
                        fixture + "/captures",
                    )
                )
            )
        captures = parsed(
            "["
            + ",".join(
                run(
                    "python3",
                    "-c",
                    "from pathlib import Path; import sys; print(Path(sys.argv[1]).read_text())",
                    fixture + "/captures",
                )
                .strip()
                .splitlines()
            )
            + "]"
        )
        assert len(captures) == 5 and all(not item["panelVisible"] for item in captures)
        print(
            "Five native capture buttons, compiled command handoff and panel-free compositor captures: passed"
        )
    ipc("settings-test", "mockClosingActions", fixture + "/launches")
    for item in state()["actions"]:
        if not item["keepOpen"]:
            if not state()["open"]:
                ipc("quick-settings", "toggle")
            ipc("settings-test", "activate", item["id"])
            assert not state()["open"]
            wait_for(
                lambda id=item["id"]: (
                    id
                    in run(
                        "python3",
                        "-c",
                        "from pathlib import Path; import sys; p=Path(sys.argv[1]); print(p.read_text() if p.exists() else '')",
                        fixture + "/launches",
                    ).splitlines()
                )
            )
    run("hyprctl", "output", "create", "headless", "SettingsMonitor")
    created_monitor = True
    run("hyprctl", "dispatch", 'hl.dsp.focus({ monitor = "SettingsMonitor" })')
    time.sleep(0.5)
    ipc("quick-settings", "toggle")
    wait_for(lambda: state()["monitor"] == "SettingsMonitor")
    ipc("settings-test", "setLocked", "true")
    wait_for(lambda: parsed(run("hyprctl", "-j", "locked"))["locked"])
    ipc("quick-settings", "toggle")
    ipc("quick-settings", "toggle")
    assert parsed(run("hyprctl", "-j", "locked"))["locked"]
    ipc("settings-test", "setLocked", "false")
    wait_for(lambda: not parsed(run("hyprctl", "-j", "locked"))["locked"])
    assert run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit) == pid
    assert run("readlink", "-f", "/run/current-system").strip() == system
    journal = run("journalctl", "--user", "-u", unit, "--no-pager")
    assert not re.search(
        r"TypeError|ReferenceError|failed to load|Cannot read property",
        journal,
        re.IGNORECASE,
    )
    if waybar_active is not None:
        bar_journal = run("journalctl", "--user", "-u", bar_unit, "--no-pager")
        assert "Error parsing JSON" not in bar_journal
    print(
        "Quick settings live actions, failure feedback, detached launches, palettes, monitor, lock, Escape/outside dismissal and stable process: passed"
    )
finally:
    ipc("settings-test", "setLocked", "false")
    if registered_config:
        run("rm", named_config)
    if created_monitor:
        run("hyprctl", "output", "remove", "SettingsMonitor")
    if temperature is not None:
        run("hyprctl", "hyprsunset", "temperature", str(temperature))
    if (
        original_notifications is not None
        and parsed(run("notification-mode", "status"))["class"]
        != original_notifications
    ):
        run("notification-mode", "toggle")
    run("systemctl", "--user", "stop", unit)
    if waybar_active is not None:
        run("systemctl", "--user", "stop", bar_unit)
        if waybar_active:
            run("systemctl", "--user", "start", "waybar")
    run("desktop-theme", original)
    run("rm", "-rf", fixture)
