import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Scope {
  id: root
  property bool open: false
  property bool panelHovered: false
  onOpenChanged: Quickshell.execDetached(@WAYBAR_REFRESH@)
  property var targetScreen: null
  property string notifications: "unknown"
  property real temperature: NaN
  property string feedback: ""
  property string pendingLabel: ""
  readonly property var actions: @ACTIONS@

  function show() {
    const name = Hyprland.focusedMonitor?.name;
    targetScreen = Quickshell.screens.find(screen => screen.name === name) || Quickshell.screens[0];
    open = true;
    dismissTimer.stop();
    refresh();
    focusTimer.restart();
  }
  function hide() {
    open = false;
    panelHovered = false;
    dismissTimer.stop();
  }
  function toggle() { if (open) hide(); else show(); }
  function refresh() {
    if (!notificationState.running) notificationState.running = true;
    if (!nightState.running) nightState.running = true;
  }
  function activate(id) {
    const item = actions.find(action => action.id === id);
    if (!item || applyJob.running) return;
    feedback = "";
    if (!item.keepOpen) {
      hide();
      Quickshell.execDetached({ command: item.command });
      return;
    }
    pendingLabel = item.label;
    applyJob.command = item.command;
    applyJob.running = true;
  }
  function stateText(item) {
    if (item.id === "notifications") return notifications === "silenced" ? "Silenced" : notifications === "normal" ? "On" : "Unavailable";
    if (item.id === "nightlight") return isNaN(temperature) ? "Unavailable" : temperature === 6000 ? "Off" : "On";
    return "";
  }

  component SettingButton: Button {
    id: control
    required property var item
    property bool segment: false
    readonly property bool selected: item.id === Theme.mode || (item.id === "notifications" && root.notifications === "silenced") || (item.id === "nightlight" && !isNaN(root.temperature) && root.temperature !== 6000)
    readonly property string stateLabel: root.stateText(item)
    readonly property bool failed: root.feedback === "Could not update " + item.label
    implicitHeight: segment ? 38 : 48
    padding: 10
    enabled: !applyJob.running
    onClicked: root.activate(item.id)
    Accessible.name: item.label
    Accessible.description: stateLabel
    ToolTip.visible: hovered && failed
    ToolTip.text: root.feedback
    contentItem: RowLayout {
      spacing: 8
      Text {
        text: control.item.id === "notifications" && root.notifications === "normal" ? "󰂚" : control.item.glyph
        color: control.selected ? Theme.colors.base0D : Theme.detailText
        font.family: @ICON_FONT@
        font.pixelSize: control.segment ? 20 : 23
        Layout.preferredWidth: 24
        Layout.fillHeight: true
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
      }
      Text {
        text: control.item.label
        color: Theme.headingText
        font.family: @FONT@
        font.pixelSize: @FONT_SIZE@
        Layout.fillWidth: true
        Layout.fillHeight: true
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }
      Text {
        visible: !control.segment
        Layout.fillHeight: true
        verticalAlignment: Text.AlignVCenter
        text: control.stateLabel || "󰅂"
        color: control.selected ? Theme.colors.base0D : Theme.mutedText
        font.family: control.stateLabel ? @FONT@ : @ICON_FONT@
        font.pixelSize: control.stateLabel ? @FONT_SIZE@ - 2 : 18
      }
    }
    background: Rectangle {
      radius: 8
      color: control.selected ? Qt.alpha(Theme.colors.base0D, Theme.mode === "light" ? 0.16 : 0.22) : control.hovered ? Theme.colors.base02 : Theme.colors.base01
      opacity: control.enabled ? 1 : 0.6
      border.width: 1
      border.color: control.failed ? Theme.colors.base08 : control.selected || control.activeFocus ? Theme.colors.base0D : Qt.alpha(Theme.colors.base03, 0.45)
    }
  }

  IpcHandler {
    target: "quick-settings"
    function toggle(): void { root.toggle(); }
    function hide(): void { root.hide(); }
    function status(): string { return JSON.stringify({class: root.open ? "active" : ""}); }
  }
  Process {
    id: applyJob
    onExited: (code, status) => {
      root.feedback = code === 0 ? root.pendingLabel + " updated" : "Could not update " + root.pendingLabel;
      root.refresh();
    }
  }
  Process {
    id: notificationState
    command: ["notification-mode", "status"]
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.notifications = JSON.parse(text).class; }
        catch (error) { root.notifications = "unknown"; }
      }
    }
    onExited: (code, status) => { if (code !== 0) root.notifications = "unknown"; }
  }
  Process {
    id: nightState
    command: ["hyprctl", "hyprsunset", "temperature"]
    stdout: StdioCollector { onStreamFinished: root.temperature = text.trim() ? Number(text.trim()) : NaN }
    onExited: (code, status) => { if (code !== 0) root.temperature = NaN; }
  }
  Timer { interval: 2000; repeat: true; running: root.open; onTriggered: root.refresh() }
  Timer { id: dismissTimer; interval: 300; onTriggered: { if (!root.panelHovered) root.hide(); } }
  Timer { id: focusTimer; interval: 1; onTriggered: frame.forceActiveFocus() }
  HyprlandFocusGrab {
    windows: [popup]
    active: root.open
    onCleared: root.hide()
  }
  PanelWindow {
    id: popup
    visible: root.open
    screen: root.targetScreen
    color: "transparent"
    implicitWidth: 488
    implicitHeight: content.implicitHeight + 40
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    anchors { top: true; right: true }
    margins { top: 38; right: 12 }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-quick-settings"
    // Exclusive layer focus prevents Hyprland's outside-click grab dismissal.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Rectangle {
      anchors.fill: frame
      anchors.margins: -4
      color: "#28000000"
      radius: 20
    }
    Rectangle {
      id: frame
      anchors.fill: parent
      anchors.margins: 4
      color: Qt.alpha(Theme.colors.base00, 0.97)
      radius: 16
      border.color: Qt.alpha(Theme.colors.base03, 0.65)
      border.width: 1
      focus: true
      Keys.onEscapePressed: root.hide()
      HoverHandler {
        onHoveredChanged: {
          root.panelHovered = hovered;
          if (hovered) dismissTimer.stop();
          else if (root.open) dismissTimer.restart();
        }
      }
      ColumnLayout {
        id: content
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
        spacing: 12
        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "Quick settings"
            color: Theme.headingText
            font.family: @FONT@
            font.pixelSize: @FONT_SIZE@ + 4
            font.bold: true
            Layout.fillWidth: true
          }
          Button {
            id: closeButton
            implicitWidth: 28; implicitHeight: 28
            onClicked: root.hide()
            Accessible.name: "Close quick settings"
            contentItem: Text {
              text: "󰅖"
              color: Theme.mutedText
              font.family: @ICON_FONT@
              font.pixelSize: 20
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
              radius: 7
              color: closeButton.hovered ? Theme.colors.base02 : "transparent"
              border.color: closeButton.activeFocus ? Theme.colors.base0D : "transparent"
            }
          }
        }
        RowLayout {
          Layout.fillWidth: true
          spacing: 8
          Repeater {
            model: root.actions.filter(item => item.id === "light" || item.id === "dark")
            SettingButton {
              required property var modelData
              item: modelData
              segment: true
              Layout.fillWidth: true
              Layout.preferredWidth: 1
            }
          }
        }
        GridLayout {
          Layout.fillWidth: true
          columns: 2
          columnSpacing: 8
          rowSpacing: 8
          Repeater {
            model: root.actions.filter(item => item.id !== "light" && item.id !== "dark")
            SettingButton {
              required property var modelData
              item: modelData
              Layout.fillWidth: true
              Layout.preferredWidth: 1
            }
          }
        }
      }
    }
  }
}
