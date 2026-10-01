import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
  QuickSettings { id: settings }
  WlSessionLock {
    id: lock
    WlSessionLockSurface {
      Rectangle { anchors.fill: parent; color: "#204060" }
    }
  }
  IpcHandler {
    target: "settings-test"
    function setLocked(value: bool): void { lock.locked = value; }
    function activate(id: string): void { settings.activate(id); }
    function failLight(): void { settings.actions.find(item => item.id === "light").command = ["false"]; }
    function mockClosingActions(logfile: string): void {
      settings.actions.forEach(item => {
        if (!item.keepOpen) item.command = ["python3", "-c", "from pathlib import Path; import sys; p=Path(sys.argv[1]); p.write_text((p.read_text() if p.exists() else '') + sys.argv[2] + '\\n')", logfile, item.id];
      });
    }
    function snapshot(): string {
      return JSON.stringify({open: settings.open, mode: Theme.mode, background: Theme.colors.base00, notifications: settings.notifications, temperature: isNaN(settings.temperature) ? null : settings.temperature, feedback: settings.feedback, monitor: settings.targetScreen?.name, actions: settings.actions});
    }
  }
}
