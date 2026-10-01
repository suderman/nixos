"""Check declarative action wiring without launching desktop applications."""

import json
import re
import sys
from pathlib import Path

source = Path(sys.argv[1]).joinpath("QuickSettings.qml").read_text()
match = re.search(r"readonly property var actions: (.+)", source)
assert match, "Missing action model"
try:
    actions = json.loads(match[1])
except ValueError as error:
    raise AssertionError("Invalid action model") from error
expected = {
    "light": ["desktop-theme", "light"],
    "dark": ["desktop-theme", "dark"],
    "notifications": ["notification-mode", "toggle"],
    "nightlight": ["mediactl", "sunset"],
    "audio": ["sinks"],
    "bluetooth": ["kitty", "--class", "Bluetuith", "bluetuith"],
    "screenshot": ["bash", "-c", "sleep 0.25 && printscreen image"],
    "recording": ["bash", "-c", "sleep 0.25 && printscreen video"],
    "localsend": ["localsend_app"],
}
assert len(actions) == len(expected)
for item in actions:
    assert item["command"] == expected.pop(item["id"])
    assert len(item["glyph"]) == 1 and 0xF0000 <= ord(item["glyph"]) <= 0xF1FFF
    assert item["keepOpen"] == (
        item["id"] in ["light", "dark", "notifications", "nightlight"]
    )
assert not expected
assert "WlrKeyboardFocus.OnDemand" in source
assert "HyprlandFocusGrab" in source
assert "HoverHandler" in source and "interval: 300" in source
assert (
    "function status(): string" in source
    and 'class: root.open ? "active" : ""' in source
)
assert "onOpenChanged: Quickshell.execDetached(" in source
assert "-RTMIN+11" in source and "waybar-wrapped" in source
assert "IdleInhibitor" not in source
assert "Presentation:" not in source
assert not re.search(r"^\s+text: root.feedback", source, re.MULTILINE)
assert "Layout.columnSpan" not in source
labels = {item["id"]: item["label"] for item in actions}
assert labels["nightlight"] == "Night Light"
assert labels["audio"] == "Audio Outputs"
assert labels["recording"] == "Record Screen"
assert "implicitHeight: 46" not in source
assert source.count("verticalAlignment: Text.AlignVCenter") >= 4
assert "segment: true" in source
print("Quick settings command wiring and single idle-inhibitor ownership: passed")
