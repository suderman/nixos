"""Check phone scale state and recovery without touching a live compositor."""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

script = Path(sys.argv[1]).resolve()
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    monitors = root / "monitors.json"
    original = [{"name": "DP-1", "scale": 1.3333334, "width": 3840, "height": 2160}]
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
        "    if os.environ.get('MOCK_ERROR'):\n"
        "        print('IPC error'); sys.exit(0)\n"
        '    match = re.fullmatch(r\'hl.monitor\\(\\{output=("[^"]+"),scale=([0-9.]+)\\}\\)\', sys.argv[2])\n'
        "    assert match, sys.argv[2]\n"
        "    data = json.loads(path.read_text())\n"
        "    assert json.loads(match[1]) == data[0]['name']\n"
        "    data[0]['scale'] = float(match[2])\n"
        "    path.write_text(json.dumps(data)); print('ok')\n"
        "else:\n"
        "    sys.exit(1)\n"
    )
    mock.chmod(0o700)
    env = os.environ | {
        "PATH": f"{root}:{os.environ['PATH']}",
        "XDG_RUNTIME_DIR": str(root),
        "HYPRLAND_INSTANCE_SIGNATURE": "test-instance",
        "MOCK_MONITORS": str(monitors),
    }
    state = root / "sunshine-phone-test-instance.json"

    def run(action, error=False):
        return subprocess.run(
            ["bash", str(script), action],
            env=env | ({"MOCK_ERROR": "1"} if error else {}),
            capture_output=True,
            text=True,
        )

    assert run("reset").returncode == 0 and not state.exists()
    result = run("start")
    assert result.returncode == 0, result.stderr
    assert json.loads(monitors.read_text())[0]["scale"] == 2.5
    saved = state.read_text()
    assert json.loads(saved) == {"output": "DP-1", "scale": 1.3333334}
    assert state.stat().st_mode & 0o077 == 0
    assert run("start").returncode == 0 and state.read_text() == saved
    assert run("reset", error=True).returncode != 0 and state.read_text() == saved
    assert run("reset").returncode == 0 and not state.exists()
    assert json.loads(monitors.read_text()) == original
    assert run("start", error=True).returncode != 0 and state.exists()
    assert run("reset").returncode == 0 and not state.exists()
    assert run("unknown").returncode == 2
    monitors.write_text("[]")
    assert run("start").returncode != 0 and not state.exists()
    print(
        "phone scale: apply, repeated start, reset, IPC failure, and empty output checks passed"
    )
