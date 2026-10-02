"""Check mediactl backlight actions with fake hardware, also used by Sim tests."""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

HARDWARE = """import json, os, sys, time
from pathlib import Path
path = Path(os.environ['BACKLIGHT_STATE'])
args = sys.argv[1:]
state = json.loads(path.read_text())
with path.with_suffix('.calls').open('a') as log:
    log.write(json.dumps(args) + '\\n')
if '--list' in args:
    print('screen,backlight' if state['available'] else 'keyboard,leds')
    sys.exit(0)
if not state['available']: sys.exit(1)
if 'set' in args:
    if state['fail']: sys.exit(1)
    time.sleep(0.05)
    value = args[args.index('set') + 1].removesuffix('=')
    if value.endswith('%+'):
        state['percentage'] = min(100, state['percentage'] + int(value[:-2]))
    elif value.endswith('%-'):
        state['percentage'] = max(0, state['percentage'] - int(value[:-2]))
    else:
        state['percentage'] = int(value.removesuffix('%'))
    temporary = path.with_suffix('.' + str(os.getpid()))
    temporary.write_text(json.dumps(state))
    temporary.replace(path)
print('screen,backlight,' + str(state['percentage'] * 10) + ',' + str(state['percentage']) + '%,1000')
"""


def install(work, mediactl, native_osd=False):
    work.mkdir(parents=True, exist_ok=True)
    owner = Path(mediactl).read_text()
    prefix = next(
        line for line in owner.splitlines() if line.startswith("export PATH=")
    )
    owner = owner.replace(
        prefix, prefix + '\nexport PATH="$BACKLIGHT_TEST_PATH:$PATH"', 1
    )
    (work / "mediactl").write_text(owner)
    (work / "brightnessctl").write_text(f"#!{sys.executable}\n" + HARDWARE)
    if not native_osd:
        (work / "avizo-client").write_text(
            f"#!{sys.executable}\n"
            "import os, sys, json\nfrom pathlib import Path\n"
            "Path(os.environ['BACKLIGHT_STATE']).with_suffix('.osd').write_text(json.dumps(sys.argv[1:]))\n"
        )
    for file in work.iterdir():
        file.chmod(0o755)


if __name__ == "__main__":
    if sys.argv[1] == "--install":
        install(Path(sys.argv[2]), sys.argv[3], native_osd=True)
        sys.exit(0)
    with tempfile.TemporaryDirectory() as temporary:
        work = Path(temporary)
        install(work / "bin", sys.argv[1])
        state = work / "state.json"
        initial = {"percentage": 45, "available": True, "fail": False}
        state.write_text(json.dumps(initial))
        env = os.environ | {
            "BACKLIGHT_TEST_PATH": str(work / "bin"),
            "BACKLIGHT_STATE": str(state),
        }

        def run(*args):
            return subprocess.run(
                [str(work / "bin/mediactl"), *args],
                env=env,
                text=True,
                capture_output=True,
                timeout=10,
                check=False,
            )

        assert run("brightness", "get").stdout.strip() == "45"
        applied = run("brightness", "set", "20")
        assert applied.returncode == 0, applied.stderr
        assert json.loads(state.read_text())["percentage"] == 20
        assert json.loads(state.with_suffix(".osd").read_text()) == [
            "--image-resource=brightness_low_dark",
            "--progress=0.20",
            "--monitor=-1",
        ]
        assert run("dark").returncode == 0
        assert run("brightness", "get").stdout.strip() == "15"
        assert run("light").returncode == 0
        for value in ["0", "101", "-1", "1.5", "01", "", "20; touch wrong"]:
            assert run("brightness", "set", value).returncode == 64
        assert run("brightness", "set", "20", "extra").returncode == 64
        assert run("brightness", "get", "extra").returncode == 64
        assert json.loads(state.read_text())["percentage"] == 20
        state.write_text(json.dumps(initial | {"fail": True}))
        assert run("brightness", "set", "90").returncode != 0
        assert json.loads(state.read_text())["percentage"] == 45
        state.write_text(json.dumps(initial | {"available": False}))
        assert run("brightness", "get").returncode != 0
        assert run("brightness", "set", "90").returncode != 0
        assert json.loads(state.read_text())["percentage"] == 45
        print(
            "Backlight read/set validation, vendor steps/OSD, failed writes and LED-only absence: passed"
        )
