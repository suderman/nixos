"""Run vendor media controls with fake hardware and the private OSD frontend."""

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

vendor = Path(sys.argv[1])
client = Path(sys.argv[2])
with tempfile.TemporaryDirectory() as temporary:
    work = Path(temporary)
    mock = work / "hardware"
    mock.write_text(
        f"#!{sys.executable}\n"
        + """import json, os, sys
from pathlib import Path
name = Path(sys.argv[0]).name
args = sys.argv[1:]
path = Path(os.environ['MEDIA_STATE'])
state = json.loads(path.read_text())
if name == 'qs':
    state['osd'] = args
    path.write_text(json.dumps(state))
    sys.exit(int(os.environ.get('QS_FAIL', '0')))
if name == 'pactl':
    print('42\\tspeaker\\tRunning\\tRUNNING')
    sys.exit(0)
if name == 'brightnessctl':
    state['brightness_args'] = args
    path.write_text(json.dumps(state))
    print('screen,backlight,450,45%,1000')
    sys.exit(0)
group = 'sources' if '--default-source' in args or any(a.startswith('--source=') for a in args) else 'sinks'
if any(a.startswith('--list-') for a in args):
    group = 'sources' if '--list-sources' in args else 'sinks'
    print('\\n'.join(i + ' device "Running"' for i in state[group]))
    sys.exit(0)
key = next((a.split('=', 1)[1] for a in args if a.startswith(('--source=', '--sink='))), next(iter(state[group])))
device = state[group][key]
if '--get-mute' in args:
    print(str(device['mute']).lower())
    sys.exit(int(device['mute']))
if '--get-volume' in args:
    print(device['volume'])
    sys.exit(int(device['mute'] or device['volume'] == 0))
state.setdefault('calls', []).append(args)
for arg in args:
    if arg == '--unmute': device['mute'] = False
    elif arg == '--mute': device['mute'] = True
    elif arg == '--toggle-mute': device['mute'] = not device['mute']
    elif arg.startswith('--increase='): device['volume'] += int(arg.split('=')[1])
    elif arg.startswith('--decrease='): device['volume'] -= int(arg.split('=')[1])
path.write_text(json.dumps(state))
"""
    )
    mock.chmod(0o755)
    for name in ["qs", "pamixer", "pactl", "brightnessctl"]:
        (work / name).symlink_to(mock)
    frontend = work / "avizo-client"
    frontend.write_text(
        f"#!{shutil.which('bash')}\n"
        + client.read_text()
        .replace("@QS@", str(work / "qs"))
        .replace("@CONFIG@", "hyprland")
    )
    frontend.chmod(0o755)
    state = work / "state.json"
    state.write_text(
        json.dumps(
            {
                "sinks": {
                    "1": {"volume": 70, "mute": False},
                    "42": {"volume": 115, "mute": True},
                },
                "sources": {
                    "10": {"volume": 60, "mute": False},
                    "11": {"volume": 80, "mute": True},
                },
            }
        )
    )
    env = os.environ | {
        "PATH": str(work) + ":" + os.environ["PATH"],
        "MEDIA_STATE": str(state),
    }

    def read():
        try:
            return json.loads(state.read_text())
        except (OSError, ValueError) as error:
            raise AssertionError("Invalid mock hardware state") from error

    def run(command, *args, **extra):
        return subprocess.run(
            [str(vendor / "bin" / command), *args],
            env=env | extra,
            capture_output=True,
            text=True,
            timeout=10,
        )

    first = run("volumectl", "-d", "-pbu", "up")
    assert first.returncode == 0, first.stderr
    result = read()
    assert result["sinks"]["42"] == {"volume": 120, "mute": False}
    assert result["sinks"]["1"]["volume"] == 70
    assert "--allow-boost" in result["calls"][0] and "--unmute" in result["calls"][0]
    assert result["osd"] == [
        "ipc",
        "-c",
        "hyprland",
        "call",
        "media-osd",
        "display",
        "volume_high",
        "1.00",
        "-1",
    ]
    assert run("volumectl", "-d", "-pb", "down").returncode == 0
    assert read()["sinks"]["42"]["volume"] == 115
    assert run("volumectl", "-d", "-a", "toggle-mute").returncode == 0
    assert all(d["mute"] for d in read()["sinks"].values())
    assert read()["osd"][-3] == "volume_muted"
    assert run("volumectl", "-d", "-am", "toggle-mute").returncode == 0
    assert all(d["mute"] for d in read()["sources"].values())
    assert read()["osd"][-3] == "mic_muted"
    assert run("volumectl", "-d", "-am", "toggle-mute").returncode == 0
    assert not any(d["mute"] for d in read()["sources"].values())
    assert read()["osd"][-3] == "mic_unmuted"
    assert run("lightctl", "-d", "down").returncode == 0
    assert read()["brightness_args"] == ["-m", "set", "5%-"]
    assert read()["osd"][-3:] == ["brightness_medium", "0.45", "-1"]
    assert run("lightctl", "-d", "up").returncode == 0
    assert read()["brightness_args"] == ["-m", "set", "5%+"]
    before = read()["sinks"]["42"]["volume"]
    failed = run("volumectl", "-pbu", "up", QS_FAIL="1")
    assert failed.returncode != 0 and "Media action applied" in failed.stderr
    assert read()["sinks"]["42"]["volume"] == before + 5
    for image, progress, monitor in [
        ("bad", "0.5", "-1"),
        ("volume_low", "nan", "-1"),
        ("volume_low", "0.5", "-2"),
    ]:
        invalid = subprocess.run(
            [
                str(frontend),
                "--image-resource=" + image,
                "--progress=" + progress,
                "--monitor=" + monitor,
            ],
            env=env,
            capture_output=True,
            timeout=5,
        )
        assert invalid.returncode == 64
    print(
        "Vendor sink selection, boost/unmute, all-device mute, mic, brightness and OSD failure: passed"
    )
