"""Verify PipeWire restart recovery with the compiled client rule in Sim."""

import json
import os
import subprocess
import sys
import time
from pathlib import Path

check, package, *wrapper = sys.argv[1:]
assert wrapper, "Sim desktop-user wrapper required"
qs = package + "/bin/qs"


def run(*args, timeout=20):
    return subprocess.check_output([*wrapper, *args], text=True, timeout=timeout)


def wait_for(predicate):
    end = time.monotonic() + 90
    while time.monotonic() < end:
        if predicate():
            return
        time.sleep(0.1)
    raise AssertionError("PipeWire recovery timed out")


assert run("hostname").strip() == "sim"
run("hyprctl", "eval", 'assert(require("generated.host").name == "sim")')
assert not json.loads(run("hyprctl", "-j", "locked"))["locked"]
system = run("readlink", "-f", "/run/current-system")
fixture = run(
    "python3",
    "-c",
    'import tempfile; print(tempfile.mkdtemp(prefix="pipewire-runtime-"))',
).strip()
unit = f"pipewire-runtime-{os.getpid()}"
stream_unit = unit + "-stream"
output_module = None
run(
    "mkdir",
    "-p",
    fixture + "/config/pipewire/client.conf.d",
    fixture + "/state/desktop-theme",
)
run(
    "cp",
    check + "/kit/pipewire-client.conf",
    fixture + "/config/pipewire/client.conf.d/90-quickshell.conf",
)
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


def ipc(target, method):
    # The shell must stay responsive even while the audio server is absent.
    return json.loads(run(qs, "ipc", "-p", fixture, "call", target, method, timeout=3))


def audio():
    return ipc("settings-test", "audioSnapshot")


def service_active(name):
    result = subprocess.run(
        [*wrapper, "systemctl", "--user", "is-active", name],
        capture_output=True,
        text=True,
        timeout=10,
        check=False,
    )
    return result.stdout.strip() == "active"


def maps(pid):
    return run(
        "python3",
        "-c",
        "from pathlib import Path; import sys; print(Path('/proc/' + sys.argv[1] + '/maps').read_text())",
        str(pid),
    )


def make_output():
    global output_module
    output_module = run(
        "pactl", "load-module", "module-null-sink", "sink_name=restart_output"
    ).strip()
    run("pactl", "set-default-sink", "restart_output")
    wait_for(lambda: audio()["sink"] == "restart_output" and audio()["sinkReady"])


try:
    run(
        "systemd-run",
        "--user",
        "--collect",
        "--unit=" + unit,
        "--setenv=XDG_CONFIG_HOME=" + fixture + "/config",
        "--setenv=XDG_STATE_HOME=" + fixture + "/state",
        qs,
        "-p",
        fixture,
    )
    for _ in range(50):
        ready = subprocess.run(
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
            timeout=3,
            check=False,
        )
        if ready.returncode == 0:
            break
        time.sleep(0.1)
    else:
        raise AssertionError("Quickshell did not start")
    pid = run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit).strip()
    assert "libpipewire-module-rt.so" not in maps(pid)
    make_output()
    # The same client drop-in must leave actual audio streams' RT module alone.
    run(
        "systemd-run",
        "--user",
        "--collect",
        "--unit=" + stream_unit,
        "--setenv=XDG_CONFIG_HOME=" + fixture + "/config",
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
    stream_pid = run(
        "systemctl", "--user", "show", "-p", "MainPID", "--value", stream_unit
    ).strip()
    wait_for(lambda: "libpipewire-module-rt.so" in maps(stream_pid))
    run(qs, "ipc", "-p", fixture, "call", "quick-settings", "toggle")
    for cycle in range(2):
        run(
            "systemctl",
            "--user",
            "stop",
            "--no-block",
            "pipewire.service",
            "pipewire.socket",
        )
        wait_for(lambda: not audio()["sinkReady"])
        output_module = None  # Server teardown removed the old module.
        for _ in range(5):
            assert ipc("settings-test", "snapshot")["open"]
            time.sleep(0.1)
        mode = "light" if cycle == 0 else "dark"
        # Isolate watcher recovery from desktop-theme's unrelated app refreshes.
        run(
            "python3",
            "-c",
            "from pathlib import Path; import sys; p=Path(sys.argv[1]); tmp=p.with_name('next'); tmp.write_text(sys.argv[2]+'\\n'); tmp.replace(p)",
            fixture + "/state/desktop-theme/mode",
            mode,
        )
        wait_for(
            lambda selected=mode: ipc("settings-test", "snapshot")["mode"] == selected
        )
        run(
            "systemctl",
            "--user",
            "start",
            "--no-block",
            "pipewire.service",
            "pipewire-pulse.service",
            "wireplumber.service",
        )
        wait_for(
            lambda: all(
                service_active(name)
                for name in ["pipewire", "pipewire-pulse", "wireplumber"]
            )
        )
        make_output()
        run("pactl", "set-sink-volume", "restart_output", "35%")
        wait_for(lambda: abs(audio()["volume"] - 0.35) < 0.01)
        assert (
            run("systemctl", "--user", "show", "-p", "MainPID", "--value", unit).strip()
            == pid
        )
        assert ipc("settings-test", "snapshot")["open"]
    assert run("readlink", "-f", "/run/current-system") == system
    print(
        "PipeWire restart recovery, absent-server IPC/theme, stable shell and player RT isolation: passed"
    )
finally:
    # Kill only owned test processes if the baseline package wedges. Do not wait
    # on its normal exit path, which is exactly the failure being checked.
    for name in [stream_unit, unit]:
        subprocess.run(
            [*wrapper, "systemctl", "--user", "kill", "--signal=KILL", name],
            capture_output=True,
            timeout=10,
            check=False,
        )
    run(
        "systemctl",
        "--user",
        "start",
        "--no-block",
        "pipewire.service",
        "pipewire-pulse.service",
        "wireplumber.service",
    )
    if output_module is not None:
        run("pactl", "unload-module", output_module)
    run("rm", "-rf", fixture)
