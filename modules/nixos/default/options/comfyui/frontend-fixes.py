"""Repair the prebuilt image's static frontend assets without changing Python deps."""

import re
import stat
from importlib.util import find_spec
from pathlib import Path


def write_asset(path, content):
    path.chmod(path.stat().st_mode | stat.S_IWUSR)
    path.write_text(content)


# The optional event subscription runs before setup() has assigned the graph.
# Guard the read itself, not console.error in the rootGraph getter.
frontend = find_spec("comfyui_frontend_package")
assert frontend is not None and frontend.origin is not None
assets = Path(frontend.origin).parent / "static" / "assets"
for path in assets.glob("settingStore-*.js"):
    original = path.read_text()
    fixed, count = re.subn(
        r"([\w$]+)\.rootGraph\?\.events",
        r"\1.isGraphReady?\1.rootGraph.events:undefined",
        original,
    )
    if count:
        write_asset(path, fixed)
        print(
            f"Guarded {count} pre-initialization graph subscription(s) in {path.name}"
        )

# The bundled Impact Pack imports a Clipspace module removed from the frontend.
# Use the upstream editor fix, preserving the bundled Python nodes and their deps.
for path in Path("/nix/store").glob("*-comfyui-impact-pack-*/js/impact-sam-editor.js"):
    if '"../../extensions/core/clipspace.js"' in path.read_text():
        write_asset(path, Path(__file__).with_name("impact-sam-editor.js").read_text())
        print("Applied upstream Impact SAM editor fix")
