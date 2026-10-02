"""Check Laptop mode changes and recovery without touching a live compositor."""

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

script = Path(sys.argv[1]).resolve()
profiles = json.loads(Path(sys.argv[2]).read_text())
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    monitors = root / "monitors.json"
    original = [
        {
            "name": profiles["normal"]["output"],
            "width": 3840,
            "height": 2160,
            "refreshRate": 160.00101,
            "scale": 1.3333334,
            "disabled": False,
            "x": 0,
            "y": 0,
            "transform": 0,
            "currentFormat": "XRGB8888",
            "activeWorkspace": {"id": 5},
        }
    ]
    monitors.write_text(json.dumps(original))
    mock = root / "hyprctl"
    mock.write_text(
        f"#!{sys.executable}\n"
        "import json, os, re, sys\n"
        "from pathlib import Path\n"
        "path = Path(os.environ['MOCK_MONITORS'])\n"
        "if sys.argv[1:] == ['-j', 'monitors']:\n"
        "    print(path.read_text())\n"
        "elif sys.argv[1] == 'eval':\n"
        "    with open(os.environ['MOCK_CALLS'], 'a') as log:\n"
        "        log.write(sys.argv[2] + '\\n')\n"
        "    if os.environ.get('MOCK_ERROR'):\n"
        "        print('IPC error'); sys.exit(0)\n"
        "    rule = sys.argv[2]\n"
        "    assert rule.startswith('hl.monitor({') and rule.endswith('})'), rule\n"
        '    pairs = re.findall(r\'(\\w+)=("[^"]+")\', rule)\n'
        "    profile = {key: json.loads(value) for key, value in pairs}\n"
        "    assert set(profile) == {'output', 'mode', 'scale'}, profile\n"
        "    data = json.loads(path.read_text())\n"
        "    monitor = next(m for m in data if m['name'] == profile['output'])\n"
        "    mode = re.fullmatch(r'(\\d+)x(\\d+)@([0-9.]+)Hz', profile['mode'])\n"
        "    monitor.update(width=int(mode[1]), height=int(mode[2]),\n"
        "                   refreshRate=float(mode[3]), scale=float(profile['scale']))\n"
        "    if os.environ.get('MOCK_FALLBACK') and profile == json.loads(os.environ['laptopProfile']):\n"
        "        monitor['width'] = 1920\n"
        "    path.write_text(json.dumps(data)); print('ok')\n"
        "else:\n"
        "    sys.exit(1)\n"
    )
    mock.chmod(0o700)
    calls = root / "calls"
    env = os.environ | {
        "PATH": f"{root}:{os.environ['PATH']}",
        "MOCK_MONITORS": str(monitors),
        "MOCK_CALLS": str(calls),
        "normalProfile": json.dumps(profiles["normal"]),
        "laptopProfile": json.dumps(profiles["laptop"]),
    }

    def run(action, **overrides):
        return subprocess.run(
            ["bash", str(script), action],
            env=env | overrides,
            capture_output=True,
            text=True,
        )

    assert run("reset").returncode == 0
    result = run("start")
    assert result.returncode == 0, result.stderr
    laptop = json.loads(monitors.read_text())[0]
    target = re.fullmatch(r"(\d+)x(\d+)@([0-9.]+)Hz", profiles["laptop"]["mode"])
    assert (
        laptop["width"],
        laptop["height"],
        laptop["refreshRate"],
        laptop["scale"],
    ) == (
        int(target[1]),
        int(target[2]),
        float(target[3]),
        float(profiles["laptop"]["scale"]),
    )
    for key in ("x", "y", "transform", "currentFormat", "activeWorkspace"):
        assert laptop[key] == original[0][key]
    assert run("start").returncode == 0
    assert run("reset").returncode == 0
    assert run("reset").returncode == 0
    restored = json.loads(monitors.read_text())[0]
    assert (restored["width"], restored["height"]) == (3840, 2160)
    assert abs(restored["scale"] - original[0]["scale"]) < 0.01
    assert run("start").returncode == 0 and run("reset").returncode == 0
    assert run("start", MOCK_ERROR="1").returncode != 0
    assert "IPC error" in run("reset", MOCK_ERROR="1").stderr
    assert run("start", MOCK_FALLBACK="1").returncode != 0
    assert json.loads(monitors.read_text())[0]["width"] == 3840
    assert "3840x2160@160.00Hz" in calls.read_text().splitlines()[-1]
    assert run("unknown").returncode == 2
    before = calls.read_text()
    monitors.write_text("[]")
    assert run("start").returncode != 0 and calls.read_text() == before
    monitors.write_text(json.dumps([original[0] | {"name": "HDMI-A-1"}]))
    assert run("start").returncode != 0 and calls.read_text() == before
    other = original[0] | {"name": "HDMI-A-1"}
    monitors.write_text(json.dumps([other, original[0]]))
    assert run("start").returncode == 0
    assert json.loads(monitors.read_text())[0] == other
    assert run("reset").returncode == 0
    print(
        "Laptop: apply, repeat/reset, output selection, IPC error, and fallback rollback passed"
    )
