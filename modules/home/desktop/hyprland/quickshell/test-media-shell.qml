import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
  id: root
  MediaOsd { id: osd }
  WlSessionLock {
    id: lock
    WlSessionLockSurface {
      Rectangle {
        anchors.fill: parent
        color: "#204060"
        Text { anchors.centerIn: parent; text: "Sim media lock test"; color: "white"; font.pixelSize: 32 }
      }
    }
  }
  IpcHandler {
    target: "media-test"
    function setLocked(value: bool): void { lock.locked = value; }
    function lifetime(milliseconds: int): void { osd.timeout = milliseconds; }
    function snapshot(): string {
      return JSON.stringify({open: osd.open, image: osd.image, progress: osd.progress,
        screen: osd.targetScreen?.name, secure: lock.secure, screens: Quickshell.screens.map(screen => screen.name),
        background: Theme.colors.base00, kind: osd.kind, muted: osd.muted});
    }
  }
}
