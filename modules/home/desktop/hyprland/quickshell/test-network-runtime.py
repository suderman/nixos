"""Exercise native network status and real nmcli writes on private D-Bus in Sim."""

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

check, package, *wrapper = sys.argv[1:]
assert wrapper, "Sim desktop-user wrapper required"
qs = package + "/bin/qs"


def run(*args):
    return subprocess.check_output([*wrapper, *args], text=True, timeout=20)


def write(path, content):
    run(
        "python3",
        "-c",
        "from pathlib import Path; import sys; Path(sys.argv[1]).write_text(sys.argv[2])",
        path,
        content,
    )


assert run("hostname").strip() == "sim"
run("hyprctl", "eval", 'assert(require("generated.host").name == "sim")')
assert not json.loads(run("hyprctl", "-j", "locked"))["locked"]
system = run("readlink", "-f", "/run/current-system")
original_mode = run("desktop-theme", "get").strip()
fixture = run(
    "python3",
    "-c",
    'import tempfile; print(tempfile.mkdtemp(prefix="network-runtime-"))',
).strip()
unit = f"network-runtime-{os.getpid()}"
units = [unit, unit + "-missing", unit + "-manager", unit + "-bus"]
address = "unix:path=" + fixture + "/bus"
run(
    "cp",
    *[
        check + "/kit/config/" + name
        for name in [
            "Theme.qml",
            "QuickSettings.qml",
            "AudioControls.qml",
            "BluetoothControls.qml",
            "BrightnessControls.qml",
            "NetworkControls.qml",
        ]
    ],
    fixture,
)
for source, target in [
    ("test-settings-shell.qml", "shell.qml"),
    ("test-networkmanager.py", "manager.py"),
]:
    write(fixture + "/" + target, Path(__file__).with_name(source).read_text())


def ipc(method, *args, path=fixture):
    return run(qs, "ipc", "-p", path, "call", "settings-test", method, *args)


def state(path=fixture):
    return json.loads(ipc("networkSnapshot", path=path))


def wait_for(predicate):
    end = time.monotonic() + 10
    while time.monotonic() < end:
        if predicate():
            return
        time.sleep(0.05)
    raise AssertionError("Network did not converge: " + str(state()))


def control(method, *args):
    return run(
        "busctl",
        "--address=" + address,
        "call",
        "org.example.SettingsTest",
        "/",
        "org.example.SettingsTest",
        method,
        *args,
    )


def service_owned():
    return (
        run(
            "busctl",
            "--address=" + address,
            "call",
            "org.freedesktop.DBus",
            "/org/freedesktop/DBus",
            "org.freedesktop.DBus",
            "NameHasOwner",
            "s",
            "org.freedesktop.NetworkManager",
        ).strip()
        == "b true"
    )


def point(name, path=fixture):
    p = json.loads(ipc("audioPoint", name, path=path))
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


def click(name):
    p = point(name)
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


def calls():
    return [
        json.loads(line)
        for line in run(
            "python3",
            "-c",
            "from pathlib import Path; import sys; print(Path(sys.argv[1]).read_text())",
            fixture + "/calls",
        ).splitlines()
        if line
    ]


def launch(path, name):
    run(
        "systemd-run",
        "--user",
        "--collect",
        "--unit=" + name,
        "--setenv=DBUS_SYSTEM_BUS_ADDRESS=" + address,
        qs,
        "-p",
        path,
    )
    for _ in range(100):
        probe = subprocess.run(
            [
                *wrapper,
                qs,
                "ipc",
                "-p",
                path,
                "call",
                "settings-test",
                "networkSnapshot",
            ],
            capture_output=True,
            timeout=3,
            check=False,
        )
        if probe.returncode == 0:
            return
        time.sleep(0.05)
    raise AssertionError(run("journalctl", "--user", "-u", name, "--no-pager"))


try:
    run(
        "systemd-run",
        "--user",
        "--collect",
        "--unit=" + units[3],
        "dbus-daemon",
        "--session",
        "--nofork",
        "--address=" + address,
    )
    run(
        "systemd-run",
        "--user",
        "--collect",
        "--unit=" + units[2],
        check + "/test-python/bin/python3",
        fixture + "/manager.py",
        address,
        fixture + "/calls",
    )
    for _ in range(100):
        probe = subprocess.run(
            [
                *wrapper,
                "busctl",
                "--address=" + address,
                "get-property",
                "org.freedesktop.NetworkManager",
                "/org/freedesktop/NetworkManager",
                "org.freedesktop.NetworkManager",
                "WirelessEnabled",
            ],
            capture_output=True,
            timeout=3,
            check=False,
        )
        if probe.returncode == 0:
            break
        time.sleep(0.05)
    else:
        raise AssertionError(run("journalctl", "--user", "-u", units[2], "--no-pager"))
    launch(fixture, unit)
    pid = run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit)
    wait_for(
        lambda: state()["name"] == "Sim Wi-Fi" and state()["status"] == "Connected"
    )
    run(qs, "ipc", "-p", fixture, "call", "quick-settings", "toggle")
    time.sleep(0.3)
    assert not any(call["method"] == "Set" for call in calls()), (
        "Panel startup changed networking"
    )
    control("Denied", "b", "true")
    click("networkPower")
    wait_for(lambda: state()["failed"] and not state()["busy"])
    assert state()["powered"] and state()["open"]
    control("Denied", "b", "false")
    click("networkPower")
    wait_for(lambda: not state()["powered"] and state()["status"] == "Off")
    click("networkPower")
    wait_for(lambda: state()["powered"] and not state()["busy"])
    control("Hardware", "b", "false")
    wait_for(lambda: state()["blocked"] and state()["status"] == "Blocked")
    assert not point("networkPower")["enabled"]
    control("Hardware", "b", "true")
    control("Radio", "b", "false")
    wait_for(lambda: state()["status"] == "Off")
    control("Radio", "b", "true")
    control("State", "su", "wifi", "60")
    wait_for(lambda: state()["status"] == "Connecting...")
    control("State", "su", "wifi", "30")
    wait_for(lambda: state()["status"] == "Disconnected")
    control("State", "su", "wifi", "100")
    wait_for(
        lambda: state()["name"] == "Sim Wi-Fi" and state()["status"] == "Connected"
    )
    for mode in ["light", "dark"]:
        run("desktop-theme", mode)
        wait_for(lambda selected=mode: json.loads(ipc("snapshot"))["mode"] == selected)
        if os.environ.get("QUICK_SETTINGS_SCREENSHOTS"):
            run("ydotool", "mousemove", "--absolute", "-x", "500", "-y", "36")
            time.sleep(0.1)  # Leave tooltip targets but stay within the panel.
            run(
                os.environ["QUICK_SETTINGS_GRIM"],
                os.environ["QUICK_SETTINGS_SCREENSHOTS"] + "/network-" + mode + ".png",
            )
    control("Devices", "s", "wired")
    wait_for(lambda: not state()["wifi"] and state()["name"] == "Ethernet")
    assert state()["status"] == "Connected"
    assert not point("networkPower")["visible"]
    control("Devices", "s", "both")
    control("State", "su", "wifi", "30")
    wait_for(lambda: state()["wifi"] and state()["name"] == "Ethernet")
    control("Devices", "s", "wired")
    control("State", "su", "wifi", "100")
    control("State", "su", "wired", "30")
    wait_for(lambda: state()["status"] == "Disconnected")
    control("Devices", "s", "none")
    wait_for(lambda: state()["name"] == "No network device")
    assert not point("networkPicker")["enabled"]
    control("Devices", "s", "wifi")
    wait_for(lambda: state()["name"] == "Sim Wi-Fi")
    ipc("mockClosingActions", fixture + "/launches")
    click("networkPicker")
    wait_for(lambda: not state()["open"])
    wait_for(
        lambda: (
            run(
                "python3",
                "-c",
                "from pathlib import Path; import sys; p=Path(sys.argv[1]); print(p.read_text() if p.exists() else '')",
                fixture + "/launches",
            ).strip()
            == "network"
        )
    )
    recorded = calls()
    assert not any(
        call["method"]
        in [
            "RequestScan",
            "CheckConnectivity",
            "ActivateConnection",
            "AddAndActivateConnection",
            "Update",
            "Delete",
            "GetSecrets",
        ]
        for call in recorded
    )
    writes = [call for call in recorded if call["method"] == "Set"]
    assert len(writes) == 3 and all(
        call["property"] == "WirelessEnabled" for call in writes
    )
    assert run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit) == pid
    # Pinned Networking chooses its backend only at startup. Probe missing
    # service separately without restarting Sim's real NetworkManager.
    control("Service", "b", "false")
    wait_for(lambda: not service_owned())
    assert not state()["open"]  # Existing process must remain responsive.
    assert state()["available"] and state()["name"] == "Sim Wi-Fi"  # Cached state.
    run("mkdir", fixture + "/missing")
    run(
        "cp",
        *[
            fixture + "/" + name
            for name in [
                "Theme.qml",
                "QuickSettings.qml",
                "AudioControls.qml",
                "BluetoothControls.qml",
                "BrightnessControls.qml",
                "NetworkControls.qml",
                "shell.qml",
            ]
        ],
        fixture + "/missing",
    )
    launch(fixture + "/missing", units[1])
    assert not state(fixture + "/missing")["available"]
    assert state(fixture + "/missing")["name"] == "Network unavailable"
    control("Service", "b", "true")
    wait_for(service_owned)
    assert not state(fixture + "/missing")["available"]  # Document native limit.
    assert run("readlink", "-f", "/run/current-system") == system
    journal = run("journalctl", "--user", "-u", unit, "--no-pager")
    assert not re.search(
        r"TypeError|ReferenceError|failed to load|Cannot read property",
        journal,
        re.IGNORECASE,
    )
    print(
        "Native network status, real radio writes/denial, hardware block, external sync, wired/no-device/hotplug and picker handoff: passed"
    )
    print(
        "Native backend startup/service-loss limitation confirmed; no automatic recovery claimed"
    )
finally:
    for name in units:
        subprocess.run(
            [*wrapper, "systemctl", "--user", "stop", name],
            capture_output=True,
            timeout=20,
            check=False,
        )
    run("desktop-theme", original_mode)
    run("rm", "-rf", fixture)
