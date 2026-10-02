"""Exercise Quickshell's real file watcher without a compositor or user session."""

import argparse
import json
import os
import subprocess
import tempfile
import time
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("package")
parser.add_argument("config")
parser.add_argument("assets")
parser.add_argument("--static", action="store_true")
parser.add_argument("--default-mode", choices=["dark", "light"], default="dark")
args = parser.parse_args()
qs = str(Path(args.package) / "bin/qs")
with tempfile.TemporaryDirectory() as temporary:
    work = Path(temporary)
    state = work / "state/desktop-theme"
    state.mkdir(parents=True)
    runtime = work / "runtime"
    runtime.mkdir(mode=0o700)
    (work / "Theme.qml").write_text((Path(args.config) / "Theme.qml").read_text())
    (work / "shell.qml").write_text("""import Quickshell
import Quickshell.Io
Scope {
  IpcHandler {
    target: "theme-test"
    function snapshot(): string {
      return JSON.stringify({ mode: Theme.mode, colors: Theme.colors, text: {
        heading: Theme.headingText, detail: Theme.detailText,
        muted: Theme.mutedText, selected: Theme.selectedText
      } });
    }
  }
}
""")
    env = os.environ | {
        "HOME": temporary,
        "XDG_CONFIG_HOME": str(work / "config"),
        "XDG_STATE_HOME": str(work / "state"),
        "XDG_RUNTIME_DIR": str(runtime),
        "QT_QPA_PLATFORM": "offscreen",
    }
    with (work / "log").open("w+") as log:
        process = subprocess.Popen(
            [qs, "-p", temporary], env=env, stdout=log, stderr=log
        )
        try:

            def expect(mode):
                selected = args.default_mode if args.static else mode
                palette = (
                    Path(args.assets)
                    if args.static
                    else Path(args.assets) / selected / "palette.json"
                )
                colors = json.loads(palette.read_text())
                light = selected == "light"
                expected = {
                    "mode": selected,
                    "colors": colors,
                    "text": {
                        "heading": colors["base05" if light else "base07"],
                        "detail": colors["base05" if light else "base06"],
                        "muted": colors["base05" if light else "base04"],
                        "selected": "#ffffff" if light else colors["base00"],
                    },
                }
                deadline = time.monotonic() + 10
                while True:
                    result = subprocess.run(
                        [qs, "ipc", "-p", temporary, "call", "theme-test", "snapshot"],
                        env=env,
                        capture_output=True,
                        text=True,
                        timeout=5,
                        check=False,
                    )
                    if result.returncode == 0 and json.loads(result.stdout) == expected:
                        break
                    if process.poll() is not None or time.monotonic() > deadline:
                        log.seek(0)
                        raise AssertionError(log.read() + result.stdout + result.stderr)
                    time.sleep(0.1)
                assert process.poll() is None

            # A missing selection uses the declarative default. Its creation and
            # subsequent renames must all remain watched by the same process.
            expect(args.default_mode)
            for mode in ["dark", "light", "dark", "light", "dark"]:
                (state / "next").write_text(mode + "\n")
                (state / "next").replace(state / "mode")
                expect(mode)
            # Repeat bursts without waiting between writes. A reload must not
            # leave an earlier async read as the final selected mode.
            for burst in range(20):
                final = "light" if burst % 2 == 0 else "dark"
                for mode in ["dark", "light"] * 10 + [final]:
                    (state / "next").write_text(mode + "\n")
                    (state / "next").replace(state / "mode")
                expect(final)
            (state / "mode").unlink()
            expect(args.default_mode)
            (state / "next").write_text("light\n")
            (state / "next").replace(state / "mode")
            expect("light")
            kind = "static" if args.static else "dynamic"
            print(
                f"Quickshell {kind} cold startup, atomic changes and rapid selection: passed"
            )
        finally:
            process.terminate()
            process.wait(timeout=10)
