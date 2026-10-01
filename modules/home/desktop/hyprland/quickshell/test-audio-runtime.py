"""Exercise inline audio with virtual PipeWire devices in disposable Sim."""

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

config, package, *wrapper = sys.argv[1:]
assert wrapper, "Sim desktop-user wrapper required"


def run(*args):
    return subprocess.check_output([*wrapper, *args], text=True, timeout=20)


def wait_for(predicate):
    for _ in range(100):
        if predicate():
            return
        time.sleep(0.1)
    raise AssertionError("Audio state did not converge: " + ipc("audioSnapshot"))


assert run("hostname").strip() == "sim"
run("hyprctl", "eval", 'assert(require("generated.host").name == "sim")')
system = run("readlink", "-f", "/run/current-system")
original_mode = run("desktop-theme", "get").strip()
fixture = run(
    "python3", "-c", 'import tempfile; print(tempfile.mkdtemp(prefix="audio-runtime-"))'
).strip()
qs = package + "/bin/qs"
unit = f"audio-runtime-{os.getpid()}"
modules = []
run(
    "cp",
    *[
        config + "/" + name
        for name in [
            "Theme.qml",
            "QuickSettings.qml",
            "AudioControls.qml",
            "BluetoothControls.qml",
        ]
    ],
    fixture,
)
run(
    "python3",
    "-c",
    "from pathlib import Path; import sys; Path(sys.argv[1]).write_text(sys.argv[2])",
    fixture + "/shell.qml",
    Path(__file__).with_name("test-settings-shell.qml").read_text(),
)


def ipc(method, *args):
    return run(qs, "ipc", "-p", fixture, "call", "settings-test", method, *args)


def state():
    return json.loads(ipc("audioSnapshot"))


def point(name):
    p = json.loads(ipc("audioPoint", name))
    # Wayland cannot give Qt a layer surface's global position. Read the
    # compositor's coordinates instead of treating mapToGlobal as screen space.
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


def click(name):
    p = point(name)
    assert p and p["enabled"], name
    move(p["x"], p["y"])
    run("ydotool", "click", "0xC0")


def nodes():
    return json.loads(run("pw-dump"))


try:
    for name in [
        "settings_speakers",
        "settings_headphones",
        "settings_hdmi",
        "settings_spdif",
        "settings_usb",
    ]:
        modules.append(
            run(
                "pactl",
                "load-module",
                "module-null-sink",
                "sink_name=" + name,
                "sink_properties=device.description="
                + name.replace("settings_", "Sim_"),
            ).strip()
        )
    # Remap a null sink's monitor into a normal Audio/Source node. The
    # pinned Quickshell does not recognize Audio/Source/Virtual nodes.
    modules.append(
        run(
            "pactl",
            "load-module",
            "module-remap-source",
            "master=settings_speakers.monitor",
            "source_name=settings_microphone",
            "source_properties=device.description=Sim_Microphone",
        ).strip()
    )
    run("pactl", "set-default-sink", "settings_speakers")
    run("pactl", "set-default-source", "settings_microphone")
    run("pactl", "set-sink-mute", "settings_speakers", "0")
    run("pactl", "set-source-mute", "settings_microphone", "0")
    run("systemd-run", "--user", "--collect", "--unit=" + unit, qs, "-p", fixture)
    wait_for(
        lambda: (
            subprocess.run(
                [
                    *wrapper,
                    qs,
                    "ipc",
                    "-p",
                    fixture,
                    "call",
                    "settings-test",
                    "audioSnapshot",
                ],
                capture_output=True,
                check=False,
            ).returncode
            == 0
        )
    )
    run(qs, "ipc", "-p", fixture, "call", "quick-settings", "toggle")
    wait_for(lambda: state()["sinkReady"] and state()["sourceReady"])
    assert (
        state()["sink"] == "settings_speakers"
        and state()["source"] == "settings_microphone"
    )
    pid = run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit)
    run("pactl", "set-sink-volume", "settings_speakers", "40%")
    wait_for(lambda: abs(state()["volume"] - 0.4) < 0.01)
    run("mediactl", "mute")
    wait_for(lambda: state()["muted"])
    click("speakerMute")
    wait_for(lambda: not state()["muted"])
    run("mediactl", "mic")
    wait_for(lambda: state()["micMuted"])
    click("microphoneMute")
    wait_for(lambda: not state()["micMuted"])
    # Drag the real Slider to both bounds. Reads must not reset its value.
    p = point("outputVolume")
    move(p["x"], p["y"])
    run("ydotool", "click", "0x40")
    move(p["x"] - p["width"] / 2 + 2, p["y"])
    wait_for(lambda: state()["volume"] < 0.01)
    move(p["x"] + p["width"] / 2 - 2, p["y"])
    run("ydotool", "click", "0x80")
    wait_for(lambda: abs(state()["volume"] - 1) < 0.01)
    # Slider keyboard changes must reach PipeWire too.
    click("outputVolume")
    previous = state()["volume"]
    run("ydotool", "key", "106:1", "106:0")  # KEY_RIGHT
    wait_for(lambda: state()["volume"] > previous + 0.005)
    # External boost is displayed, not silently clamped by opening the panel.
    run("pactl", "set-sink-volume", "settings_speakers", "150%")
    wait_for(lambda: abs(state()["volume"] - 1.5) < 0.01)
    run(qs, "ipc", "-p", fixture, "call", "quick-settings", "hide")
    run(qs, "ipc", "-p", fixture, "call", "quick-settings", "toggle")
    assert abs(state()["volume"] - 1.5) < 0.01
    run(
        "systemd-run",
        "--user",
        "--collect",
        "--unit=" + unit + "-stream",
        "pw-cat",
        "--playback",
        "--raw",
        "--rate",
        "48000",
        "--channels",
        "2",
        "--format",
        "f32",
        "/dev/zero",
    )
    time.sleep(0.5)
    click("outputChooser")
    wait_for(lambda: state()["expanded"])
    click("audioOutput-settings_headphones")
    wait_for(lambda: state()["sink"] == "settings_headphones" and state()["sinkReady"])
    target = next(
        n["id"] for n in state()["outputs"] if n["name"] == "settings_headphones"
    )
    wait_for(
        lambda: any(
            n.get("info", {}).get("input-node-id") == target
            for n in nodes()
            if n["type"] == "PipeWire:Interface:Link"
        )
    )
    assert state()["open"] and not state()["expanded"]
    # Hotplug a sixth output after the panel started. It must be discoverable
    # and selectable below the drawer's four-row viewport.
    modules.append(
        run(
            "pactl",
            "load-module",
            "module-null-sink",
            "sink_name=settings_buds",
            "sink_properties=device.description=Sim_Pixel_Buds",
        ).strip()
    )
    wait_for(lambda: any(n["name"] == "settings_buds" for n in state()["outputs"]))
    assert (
        next(
            i for i, n in enumerate(state()["outputs"]) if n["name"] == "settings_buds"
        )
        >= 4
    )
    click("outputChooser")
    viewport = point("audioOutputs")
    assert viewport["persistentScrollBar"] and viewport["scrollBarOpacity"] > 0
    move(viewport["x"], viewport["y"])
    run("ydotool", "mousemove", "--wheel", "-x", "0", "-y", "4")
    wait_for(
        lambda: (
            not point("audioOutputs")["scrollMoving"]
            and viewport["y"] - viewport["height"] / 2 + 18
            <= point("audioOutput-settings_buds")["y"]
            <= viewport["y"] + viewport["height"] / 2 - 18
        )
    )
    click("audioOutput-settings_buds")
    wait_for(lambda: state()["sink"] == "settings_buds" and state()["sinkReady"])
    buds = next(n["id"] for n in state()["outputs"] if n["name"] == "settings_buds")
    wait_for(
        lambda: any(
            n.get("info", {}).get("input-node-id") == buds
            for n in nodes()
            if n["type"] == "PipeWire:Interface:Link"
        )
    )
    assert state()["open"] and not state()["expanded"]
    run("pactl", "set-default-sink", "settings_speakers")
    wait_for(lambda: state()["sink"] == "settings_speakers")
    run("pactl", "set-sink-volume", "settings_speakers", "55%")
    wait_for(lambda: abs(state()["volume"] - 0.55) < 0.01)
    if os.environ.get("QUICK_SETTINGS_SCREENSHOTS"):
        for mode in ["light", "dark"]:
            run("desktop-theme", mode)
            time.sleep(0.5)
            click("outputChooser")
            run(
                os.environ["QUICK_SETTINGS_GRIM"],
                os.environ["QUICK_SETTINGS_SCREENSHOTS"] + "/audio-" + mode + ".png",
            )
            click("outputChooser")
    run("systemctl", "--user", "stop", unit + "-stream")
    for module in reversed(modules):
        run("pactl", "unload-module", module)
    modules.clear()
    # Remove Pulse's automatic dummy output too, without stopping the
    # PipeWire server. This tests device loss, not the pinned reconnect bug.
    run(
        "systemctl", "--user", "stop", "pipewire-pulse.socket", "pipewire-pulse.service"
    )
    wait_for(
        lambda: (
            not state()["sinkReady"]
            and not state()["sourceReady"]
            and not state()["outputs"]
        )
    )
    assert (
        not point("speakerMute")["enabled"]
        and not point("microphoneMute")["enabled"]
        and not point("outputVolume")["enabled"]
    )
    run("systemctl", "--user", "start", "pipewire-pulse.socket")
    run("pactl", "info")
    wait_for(lambda: state()["sinkReady"])
    assert not state()["sourceReady"] and not point("microphoneMute")["enabled"]
    assert run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit) == pid
    assert run("readlink", "-f", "/run/current-system") == system
    journal = run("journalctl", "--user", "-u", unit, "--no-pager")
    assert not re.search(
        r"TypeError|ReferenceError|Binding loop|Cannot read property|failed to load",
        journal,
        re.IGNORECASE,
    ), journal
    print(
        "Native audio slider, mute/media-key sync, six-output scrolling/hotplug, stream switching, external boost and device removal/reappearance: passed"
    )
finally:
    subprocess.run(
        [*wrapper, "systemctl", "--user", "stop", unit + "-stream"], check=False
    )
    run("systemctl", "--user", "stop", unit)
    run(
        "systemctl",
        "--user",
        "start",
        "pipewire.socket",
        "pipewire-pulse.socket",
        "wireplumber",
    )
    for module in reversed(modules):
        run("pactl", "unload-module", module)
    run("desktop-theme", original_mode)
    run("rm", "-rf", fixture)
