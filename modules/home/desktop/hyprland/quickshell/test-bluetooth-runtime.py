"""Exercise native Bluetooth controls using private BlueZ in disposable Sim."""

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

config, package, python, *wrapper = sys.argv[1:]
assert wrapper, "Sim desktop-user wrapper required"


def run(*args):
    return subprocess.check_output([*wrapper, *args], text=True, timeout=20)


assert run("hostname").strip() == "sim"
run("hyprctl", "eval", 'assert(require("generated.host").name == "sim")')
assert not json.loads(run("hyprctl", "-j", "locked"))["locked"]
system = run("readlink", "-f", "/run/current-system")
original_mode = run("desktop-theme", "get").strip()
fixture = run(
    "python3",
    "-c",
    'import tempfile; print(tempfile.mkdtemp(prefix="bluetooth-runtime-"))',
).strip()
qs = package + "/bin/qs"
unit = f"bluetooth-runtime-{os.getpid()}"
address = "unix:path=" + fixture + "/bus"
units = [unit, unit + "-bluez", unit + "-bus"]
run(
    "cp",
    *[
        config + "/" + name
        for name in [
            "Theme.qml",
            "QuickSettings.qml",
            "AudioControls.qml",
            "BluetoothControls.qml",
            "BrightnessControls.qml",
        ]
    ],
    fixture,
)
for name, target in [
    ("test-settings-shell.qml", "shell.qml"),
    ("test-bluez.py", "bluez.py"),
]:
    run(
        "python3",
        "-c",
        "from pathlib import Path; import sys; Path(sys.argv[1]).write_text(sys.argv[2])",
        fixture + "/" + target,
        Path(__file__).with_name(name).read_text(),
    )


def ipc(method, *args):
    return run(qs, "ipc", "-p", fixture, "call", "settings-test", method, *args)


def state():
    return json.loads(ipc("bluetoothSnapshot"))


def wait_for(predicate):
    for _ in range(100):
        if predicate():
            return
        time.sleep(0.05)
    raise AssertionError("Bluetooth state did not converge: " + str(state()))


def control(method, signature=None, value=None):
    return run(
        "busctl",
        "--address=" + address,
        "call",
        "org.bluez",
        "/",
        "org.example.SettingsTest",
        method,
        *([signature, value] if signature else []),
    )


def point(name, method="bluetoothPoint"):
    p = json.loads(ipc(method, name))
    layers = json.loads(run("hyprctl", "-j", "layers"))
    layer = next(
        layer
        for monitor in layers.values()
        for level in monitor["levels"].values()
        for layer in level
        if layer["namespace"] == "quickshell-quick-settings"
    )
    p["x"] += layer["x"]
    p["y"] += layer["y"]
    return p


def click(name, method="bluetoothPoint"):
    p = point(name, method)
    assert p["enabled"], name
    run(
        "ydotool",
        "mousemove",
        "--absolute",
        "-x",
        str(round(p["x"] / 2)),
        "-y",
        str(round(p["y"] / 2)),
    )
    cursor = json.loads(run("hyprctl", "-j", "cursorpos"))
    assert abs(cursor["x"] - p["x"]) < 3 and abs(cursor["y"] - p["y"]) < 3
    run("ydotool", "click", "0xC0")


try:
    run(
        "systemd-run",
        "--user",
        "--collect",
        "--unit=" + units[2],
        "dbus-daemon",
        "--session",
        "--nofork",
        "--address=" + address,
    )
    run(
        "systemd-run",
        "--user",
        "--collect",
        "--unit=" + units[1],
        python + "/bin/python3",
        fixture + "/bluez.py",
        address,
        fixture + "/calls.jsonl",
    )
    for _ in range(100):
        probe = subprocess.run(
            [
                *wrapper,
                "busctl",
                "--address=" + address,
                "call",
                "org.bluez",
                "/",
                "org.freedesktop.DBus.ObjectManager",
                "GetManagedObjects",
            ],
            capture_output=True,
            check=False,
        )
        if probe.returncode == 0:
            break
        time.sleep(0.05)
    else:
        raise AssertionError(run("journalctl", "--user", "-u", units[1], "--no-pager"))
    run(
        "systemd-run",
        "--user",
        "--collect",
        "--unit=" + unit,
        "--setenv=DBUS_SYSTEM_BUS_ADDRESS=" + address,
        qs,
        "-p",
        fixture,
    )
    for _ in range(100):
        probe = subprocess.run(
            [
                *wrapper,
                qs,
                "ipc",
                "-p",
                fixture,
                "call",
                "settings-test",
                "bluetoothSnapshot",
            ],
            capture_output=True,
            check=False,
        )
        if probe.returncode == 0:
            break
        time.sleep(0.05)
    else:
        raise AssertionError(run("journalctl", "--user", "-u", unit, "--no-pager"))
    pid = run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit)
    wait_for(
        lambda: (
            state()["adapter"] == "hci0"
            and state()["powered"]
            and len(state()["devices"]) == 1
        )
    )
    run(qs, "ipc", "-p", fixture, "call", "quick-settings", "toggle")
    click("bluetoothChooser")
    wait_for(lambda: state()["expanded"])
    device = "bluetoothDevice-00:11:22:33:44:55"
    click(device)
    wait_for(lambda: state()["devices"][0]["state"] == "Connecting")
    assert not point(device)["enabled"]
    wait_for(lambda: state()["devices"][0]["connected"])
    control("FailNext")
    click(device)
    wait_for(lambda: point(device)["failure"] == "Disconnect failed")
    assert state()["devices"][0]["connected"]
    click(device)
    wait_for(lambda: state()["devices"][0]["state"] == "Disconnecting")
    wait_for(lambda: not state()["devices"][0]["connected"])
    control("FailNext")
    click(device)
    wait_for(lambda: point(device)["failure"] == "Connection failed")
    assert point(device)["enabled"] and not state()["devices"][0]["connected"]
    click(device)  # Retry must clear the failed state and succeed.
    wait_for(
        lambda: state()["devices"][0]["connected"] and not point(device)["failure"]
    )
    control("Connected", "b", "false")
    wait_for(lambda: not state()["devices"][0]["connected"])
    control("Connected", "b", "true")
    wait_for(lambda: state()["devices"][0]["connected"])
    control("DeviceBlocked", "b", "true")
    wait_for(lambda: point(device)["stateText"] == "Blocked")
    assert not point(device)["enabled"]
    control("DeviceBlocked", "b", "false")
    wait_for(lambda: point(device)["enabled"])
    click("bluetoothPower")
    wait_for(lambda: state()["powerText"] == "Off")
    assert not point(device)["enabled"]
    click("bluetoothPower")
    wait_for(lambda: state()["powerText"] == "On")
    for value, text in [
        ("off-enabling", "Changing..."),
        ("on-disabling", "Changing..."),
        ("off-blocked", "Blocked"),
    ]:
        control("PowerState", "s", value)
        wait_for(lambda text=text: state()["powerText"] == text)
        assert not point("bluetoothPower")["enabled"]
    control("PowerState", "s", "on")
    wait_for(lambda: state()["powered"])
    control("Paired", "b", "false")
    wait_for(lambda: not state()["devices"])
    control("Paired", "b", "true")
    wait_for(lambda: len(state()["devices"]) == 1)
    click("outputChooser", "audioPoint")
    wait_for(lambda: not state()["expanded"] and state()["audioExpanded"])
    click("bluetoothChooser")
    wait_for(lambda: state()["expanded"] and not state()["audioExpanded"])
    for mode in ["light", "dark"]:
        run("desktop-theme", mode)
        wait_for(lambda mode=mode: json.loads(ipc("snapshot"))["mode"] == mode)
        if os.environ.get("QUICK_SETTINGS_SCREENSHOTS"):
            run(
                os.environ["QUICK_SETTINGS_GRIM"],
                os.environ["QUICK_SETTINGS_SCREENSHOTS"]
                + "/bluetooth-"
                + mode
                + ".png",
            )
    control("AdapterPresent", "b", "false")
    wait_for(lambda: state()["adapter"] is None and not state()["devices"])
    assert not point("bluetoothPower")["enabled"]
    control("AdapterPresent", "b", "true")
    wait_for(lambda: state()["adapter"] == "hci0" and len(state()["devices"]) == 1)
    # More settings retains the existing detached Bluetuith command.
    ipc("mockClosingActions", fixture + "/detached.log")
    click("bluetoothAdvanced")
    wait_for(lambda: not state()["open"])
    wait_for(
        lambda: (
            run(
                "python3",
                "-c",
                "from pathlib import Path; import sys; p=Path(sys.argv[1]); print(p.read_text() if p.exists() else '')",
                fixture + "/detached.log",
            ).strip()
            == "bluetooth"
        )
    )
    calls = [
        json.loads(line)
        for line in run(
            "python3",
            "-c",
            "from pathlib import Path; import sys; print(Path(sys.argv[1]).read_text())",
            fixture + "/calls.jsonl",
        ).splitlines()
        if line
    ]
    assert not any(
        call["method"] in ["StartDiscovery", "Pair", "RemoveDevice"] for call in calls
    )
    assert sum(call["method"] == "Connect" for call in calls) == 3
    assert sum(call["method"] == "Disconnect" for call in calls) == 2
    assert run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit) == pid
    assert run("readlink", "-f", "/run/current-system") == system
    journal = run("journalctl", "--user", "-u", unit, "--no-pager")
    assert not re.search(
        r"TypeError|ReferenceError|failed to load|Cannot read property",
        journal,
        re.IGNORECASE,
    )
    print(
        "Native Bluetooth power, pending/failure/retry, external sync, paired filtering, adapter hotplug and drawer lifecycle: passed"
    )
finally:
    for service in units:
        subprocess.run([*wrapper, "systemctl", "--user", "stop", service], check=False)
    run("desktop-theme", original_mode)
    run("rm", "-rf", fixture)
