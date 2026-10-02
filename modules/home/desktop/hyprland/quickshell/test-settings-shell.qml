import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Controls.Basic

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
    function brightnessSnapshot(): string {
      return JSON.stringify({available: settings.brightness.available, percentage: settings.brightness.available ? settings.brightness.percentage : null, failed: settings.brightness.failed, active: settings.brightness.active, open: settings.open});
    }
    function audioSnapshot(): string {
      const audio = settings.audio;
      return JSON.stringify({
        sink: audio.sink?.name || null, source: audio.source?.name || null,
        sinkReady: audio.sinkReady, sourceReady: audio.sourceReady,
        volume: audio.sinkReady ? audio.sink.audio.volume : null,
        muted: audio.sinkReady ? audio.sink.audio.muted : null,
        micMuted: audio.sourceReady ? audio.source.audio.muted : null,
        outputs: audio.outputs.map(node => ({name: node.name, id: node.id})),
        expanded: audio.expanded, open: settings.open
      });
    }
    function audioPoint(name: string): string {
      function find(item) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
          const match = find(child);
          if (match) return match;
        }
        return null;
      }
      const item = find(settings.audio.parent);
      const point = item?.mapToGlobal(item.width / 2, item.height / 2);
      const bar = name === "audioOutputs" ? item.ScrollBar.vertical : null;
      return JSON.stringify(point ? {x: point.x, y: point.y, width: item.width, height: item.height, enabled: item.enabled,
        persistentScrollBar: bar ? bar.policy === ScrollBar.AlwaysOn : null,
        scrollBarOpacity: bar ? bar.contentItem.opacity : null,
        scrollMoving: bar ? item.contentItem.moving : false} : null);
    }
    function bluetoothSnapshot(): string {
      const bt = settings.bluetooth;
      return JSON.stringify({
        adapter: bt.adapter?.adapterId || null, powered: bt.powered,
        powerText: bt.powerText, powerBusy: bt.powerBusy, expanded: bt.expanded,
        devices: bt.devices.map(device => ({address: device.address, name: device.name,
          connected: device.connected, state: BluetoothDeviceState.toString(device.state)})),
        audioExpanded: settings.audio.expanded, open: settings.open
      });
    }
    function bluetoothPoint(name: string): string {
      function find(item) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
          const match = find(child);
          if (match) return match;
        }
        return null;
      }
      const item = find(settings.bluetooth);
      const point = item?.mapToGlobal(item.width / 2, item.height / 2);
      return JSON.stringify(point ? {x: point.x, y: point.y, enabled: item.enabled,
        failure: item.failure || "", stateText: item.stateText || ""} : null);
    }
    function snapshot(): string {
      return JSON.stringify({open: settings.open, mode: Theme.mode, background: Theme.colors.base00, notifications: settings.notifications, temperature: isNaN(settings.temperature) ? null : settings.temperature, feedback: settings.feedback, monitor: settings.targetScreen?.name, actions: settings.actions});
    }
  }
}
