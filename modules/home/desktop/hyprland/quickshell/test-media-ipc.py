"""Verify the private frontend through stock Quickshell's typed IPC parser."""

import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

qs = Path(sys.argv[1]) / "bin/qs"
client = Path(sys.argv[2])
with tempfile.TemporaryDirectory() as temporary:
    work = Path(temporary)
    config = work / "config/quickshell/hyprland"
    config.mkdir(parents=True)
    runtime = work / "runtime"
    runtime.mkdir(mode=0o700)
    (config / "shell.qml").write_text("""import Quickshell
import Quickshell.Io
Scope {
  id: root
  property string received: ""
  IpcHandler {
    target: "media-osd"
    function display(image: string, progress: real, monitor: int): void { root.received = JSON.stringify([image, progress, monitor]); }
    function snapshot(): string { return root.received; }
  }
}
""")
    frontend = work / "client"
    frontend.write_text(
        client.read_text().replace("@QS@", str(qs)).replace("@CONFIG@", "hyprland")
    )
    env = os.environ | {
        "HOME": temporary,
        "XDG_CONFIG_HOME": str(work / "config"),
        "XDG_STATE_HOME": str(work / "state"),
        "XDG_RUNTIME_DIR": str(runtime),
        "QT_QPA_PLATFORM": "offscreen",
    }
    env.pop("WAYLAND_DISPLAY", None)
    with (work / "log").open("w+") as log:
        process = subprocess.Popen(
            [str(qs), "-c", "hyprland"], env=env, stdout=log, stderr=log
        )
        try:
            deadline = time.monotonic() + 10
            while True:
                ready = subprocess.run(
                    [str(qs), "ipc", "-c", "hyprland", "call", "media-osd", "snapshot"],
                    env=env,
                    capture_output=True,
                )
                if ready.returncode == 0:
                    break
                if process.poll() is not None or time.monotonic() > deadline:
                    log.seek(0)
                    raise AssertionError(log.read())
                time.sleep(0.1)
            subprocess.run(
                [
                    "bash",
                    str(frontend),
                    "--image-resource=mic_muted_dark",
                    "--progress=0.60",
                    "--monitor=-1",
                ],
                env=env,
                check=True,
                timeout=5,
            )
            result = subprocess.check_output(
                [str(qs), "ipc", "-c", "hyprland", "call", "media-osd", "snapshot"],
                env=env,
                text=True,
                timeout=5,
            )
            assert result.strip() == '["mic_muted",0.6,-1]'
            print(
                "Native media IPC strings, real progress and negative monitor: passed"
            )
        finally:
            process.terminate()
            process.wait(timeout=10)
