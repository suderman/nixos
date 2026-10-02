import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 8
  signal pickerRequested()
  property bool failed: false
  readonly property bool available: Networking.backend === NetworkBackendType.NetworkManager
  readonly property var devices: Networking.devices.values.filter(device => device.type === DeviceType.Wifi || device.type === DeviceType.Wired)
  readonly property var wifi: devices.find(device => device.type === DeviceType.Wifi) || null
  readonly property var current: devices.find(device => device.state === ConnectionState.Connected) || devices.find(device => device.state === ConnectionState.Connecting) || wifi || devices[0] || null
  readonly property var connection: current?.networks.values.find(network => network.connected || network.state === ConnectionState.Connecting) || null
  readonly property bool powered: Networking.wifiEnabled
  readonly property bool blocked: !!wifi && !Networking.wifiHardwareEnabled
  readonly property bool busy: radioJob.running
  readonly property string name: !available ? "Network unavailable" : !current ? "No network device" : current.type === DeviceType.Wifi ? connection?.name || "Wi-Fi" : "Ethernet"
  readonly property string status: busy ? "Changing..." : failed ? "Change failed" : !available || !current ? "" : current.type === DeviceType.Wifi && blocked ? "Blocked" : current.type === DeviceType.Wifi && !powered ? "Off" : current.state === ConnectionState.Connected ? "Connected" : current.state === ConnectionState.Connecting ? "Connecting..." : current.state === ConnectionState.Disconnecting ? "Disconnecting..." : current.state === ConnectionState.Disconnected ? "Disconnected" : "Unavailable"

  // The native setter updates its cache before writing and cannot report a
  // denied write. Use one explicit command; native signals still own status.
  Process {
    id: radioJob
    onExited: (code, status) => root.failed = code !== 0
  }
  Connections {
    target: Networking
    function onWifiEnabledChanged() { root.failed = false; }
  }
  component NetworkLabel: Text {
    textFormat: Text.PlainText
    color: Theme.headingText
    font.family: @FONT@
    font.pixelSize: @FONT_SIZE@
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }
  component NetworkButton: Button {
    id: control
    implicitHeight: 38
    padding: 8
    background: Rectangle {
      radius: 8
      color: control.hovered ? Theme.colors.base02 : Theme.colors.base01
      opacity: control.enabled ? 1 : 0.5
      border.width: 1
      border.color: root.failed ? Theme.colors.base08 : control.activeFocus ? Theme.colors.base0D : Qt.alpha(Theme.colors.base03, 0.45)
    }
  }
  NetworkButton {
    objectName: "networkPower"
    implicitWidth: 38
    visible: !!root.wifi
    enabled: root.available && !root.blocked && !root.busy
    Accessible.name: root.powered ? "Turn Wi-Fi off" : "Turn Wi-Fi on"
    ToolTip.visible: hovered
    ToolTip.text: root.failed ? "Could not change Wi-Fi radio" : root.blocked ? "Wi-Fi is blocked by hardware" : Accessible.name
    onClicked: {
      root.failed = false;
      radioJob.command = [@NMCLI@, "radio", "wifi", root.powered ? "off" : "on"];
      radioJob.running = true;
    }
    contentItem: Item {
      Text {
        id: radioGlyph
        objectName: "networkGlyph"
        text: root.powered ? "󰤨" : "󰤮"
        font.family: @ICON_FONT@
        font.pixelSize: 23
        color: root.powered && !root.blocked ? Theme.colors.base0D : Theme.mutedText
        anchors.verticalCenter: parent.verticalCenter
        // Fallback icons can be wider than the monospace advance. Center ink.
        x: (parent.width - radioMetrics.tightBoundingRect.width) / 2 - radioMetrics.tightBoundingRect.x
        TextMetrics { id: radioMetrics; font: radioGlyph.font; text: radioGlyph.text }
      }
    }
  }
  NetworkButton {
    objectName: "networkPicker"
    Layout.fillWidth: true
    enabled: root.available && !!root.current
    Accessible.name: "Choose network"
    Accessible.description: root.name + " " + root.status
    ToolTip.visible: hovered
    ToolTip.text: root.failed ? "Could not change Wi-Fi radio" : root.current?.name || root.name
    onClicked: root.pickerRequested()
    contentItem: RowLayout {
      NetworkLabel { text: root.name; Layout.fillWidth: true }
      NetworkLabel { text: root.status; color: root.failed ? Theme.colors.base08 : Theme.mutedText; font.pixelSize: @FONT_SIZE@ - 2 }
      Text {
        text: "󰅂"
        font.family: @ICON_FONT@
        font.pixelSize: 20
        color: Theme.mutedText
      }
    }
  }
}
