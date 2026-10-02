import Quickshell.Io
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

RowLayout {
  id: root
  property bool active: false
  property real percentage: NaN
  property int pending: -1
  property bool failed: false
  readonly property bool available: !isNaN(percentage)
  visible: available
  spacing: 8

  function refresh() {
    if (active && !readJob.running && !writeJob.running && pending < 0)
      readJob.running = true;
  }
  function sync() {
    if (!brightness.pressed && !writeJob.running && pending < 0)
      brightness.value = available ? percentage : 1;
  }
  function request(value) {
    pending = Math.round(value);
    failed = false;
    if (!writeJob.running) commit();
  }
  function commit() {
    const value = pending;
    pending = -1;
    writeJob.command = ["mediactl", "brightness", "set", String(value)];
    writeJob.running = true;
  }
  onActiveChanged: { if (active) refresh(); else pending = -1; }

  Process {
    id: readJob
    command: ["mediactl", "brightness", "get"]
    stdout: StdioCollector {
      onStreamFinished: {
        const value = text.trim();
        root.percentage = /^(\d|[1-9]\d|100)$/.test(value) ? Number(value) : NaN;
        root.sync();
      }
    }
    onExited: (code, status) => { if (code !== 0) root.percentage = NaN; }
  }
  Process {
    id: writeJob
    onExited: (code, status) => {
      root.failed = code !== 0;
      if (root.pending >= 1) root.commit();
      else root.refresh();
    }
  }
  // Sysfs backlight changes do not reliably emit file-watch events. Read the
  // hardware only while open, including changes made by keys or other tools.
  Timer { interval: 500; repeat: true; running: root.active; onTriggered: root.refresh() }

  Text {
    Layout.preferredWidth: 38
    text: "󰃠"
    font.family: @ICON_FONT@
    font.pixelSize: 23
    color: Theme.detailText
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }
  Slider {
    id: brightness
    objectName: "backlightBrightness"
    Layout.fillWidth: true
    implicitHeight: 38
    enabled: root.available
    from: 1
    to: 100
    stepSize: 1
    Accessible.name: "Screen brightness"
    // Keep the display lit. Existing keys retain their original step behavior.
    onMoved: root.request(value)
    // A conditional Binding restores its old value when pressed. Sync reads
    // explicitly so clicking the minimum still emits moved and writes hardware.
    onPressedChanged: { if (!pressed) root.sync(); }
    ToolTip.visible: hovered
    ToolTip.text: root.failed ? "Could not change screen brightness" : "Screen brightness"
    background: Rectangle {
      x: brightness.leftPadding
      y: brightness.topPadding + brightness.availableHeight / 2 - height / 2
      implicitHeight: 6
      width: brightness.availableWidth
      height: implicitHeight
      radius: 3
      color: Theme.colors.base02
      Rectangle {
        width: brightness.visualPosition * parent.width
        height: parent.height
        radius: 3
        color: root.failed ? Theme.colors.base08 : Theme.colors.base0D
      }
    }
    handle: Rectangle {
      x: brightness.leftPadding + brightness.visualPosition * (brightness.availableWidth - width)
      y: brightness.topPadding + brightness.availableHeight / 2 - height / 2
      implicitWidth: 16
      implicitHeight: 16
      radius: 8
      color: root.failed ? Theme.colors.base08 : Theme.colors.base0D
      border.width: brightness.activeFocus ? 2 : 0
      border.color: Theme.headingText
    }
  }
  Text {
    Layout.preferredWidth: 44
    text: root.available ? Math.round(root.percentage) + "%" : "--"
    font.family: @FONT@
    font.pixelSize: @FONT_SIZE@
    color: Theme.headingText
    horizontalAlignment: Text.AlignRight
    verticalAlignment: Text.AlignVCenter
  }
}
