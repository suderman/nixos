import Quickshell.Bluetooth
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
  id: root
  spacing: 8
  signal advancedRequested()
  property bool expanded: false
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var devices: adapter ? adapter.devices.values.filter(device => device.paired) : []
  readonly property bool powered: !!adapter && adapter.state === BluetoothAdapterState.Enabled
  readonly property bool powerBusy: !!adapter && (adapter.state === BluetoothAdapterState.Enabling || adapter.state === BluetoothAdapterState.Disabling)
  readonly property string powerText: !adapter ? "No adapter" : adapter.state === BluetoothAdapterState.Blocked ? "Blocked" : powerBusy ? "Changing..." : powered ? "On" : "Off"

  component BluetoothLabel: Text {
    color: Theme.headingText
    font.family: @FONT@
    font.pixelSize: @FONT_SIZE@
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }
  component BluetoothButton: Button {
    id: control
    implicitHeight: 38
    padding: 8
    background: Rectangle {
      radius: 8
      color: control.hovered ? Theme.colors.base02 : Theme.colors.base01
      opacity: control.enabled ? 1 : 0.5
      border.width: 1
      border.color: control.activeFocus ? Theme.colors.base0D : Qt.alpha(Theme.colors.base03, 0.45)
    }
  }
  RowLayout {
    Layout.fillWidth: true
    spacing: 8
    BluetoothButton {
      objectName: "bluetoothPower"
      implicitWidth: 38
      enabled: !!root.adapter && !root.powerBusy && root.adapter.state !== BluetoothAdapterState.Blocked
      Accessible.name: root.powered ? "Turn Bluetooth off" : "Turn Bluetooth on"
      ToolTip.visible: hovered
      ToolTip.text: root.powerText === "Blocked" ? "Bluetooth is blocked by rfkill" : Accessible.name
      onClicked: root.adapter.enabled = !root.powered
      contentItem: Text {
        text: "󰂯"
        font.family: @ICON_FONT@
        font.pixelSize: 23
        color: root.powered ? Theme.colors.base0D : Theme.mutedText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }
    BluetoothButton {
      objectName: "bluetoothChooser"
      Layout.fillWidth: true
      Accessible.name: "Show paired Bluetooth devices"
      onClicked: root.expanded = !root.expanded
      contentItem: RowLayout {
        BluetoothLabel { text: "Bluetooth"; Layout.fillWidth: true }
        BluetoothLabel { text: root.powerText; color: Theme.mutedText }
        Text {
          text: root.expanded ? "󰅃" : "󰅀"
          font.family: @ICON_FONT@
          font.pixelSize: 20
          color: Theme.mutedText
        }
      }
    }
  }
  BluetoothLabel {
    visible: root.expanded && (!root.powered || root.devices.length === 0)
    Layout.fillWidth: true
    text: !root.adapter ? "No Bluetooth adapter" : !root.powered ? (root.powerText === "Blocked" ? "Bluetooth is blocked by rfkill" : "Turn Bluetooth on to connect") : "No paired devices"
    color: Theme.mutedText
  }
  ScrollView {
    visible: root.expanded && root.devices.length > 0
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(root.devices.length * 44, 176)
    contentWidth: availableWidth
    clip: true
    Column {
      width: parent.width
      Repeater {
        model: root.devices
        BluetoothButton {
          id: deviceButton
          required property var modelData
          property int requested: -1
          property string failure: ""
          readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
          readonly property string stateText: modelData.blocked ? "Blocked" : busy ? (modelData.state === BluetoothDeviceState.Connecting ? "Connecting..." : "Disconnecting...") : failure || (modelData.connected ? "Connected" : "Disconnected")
          objectName: "bluetoothDevice-" + modelData.address
          width: parent.width
          height: 44
          enabled: root.powered && !busy && !modelData.blocked
          Accessible.name: modelData.name || modelData.address
          Accessible.description: stateText
          onClicked: {
            failure = "";
            requested = modelData.connected ? 0 : 1;
            if (requested) modelData.connect(); else modelData.disconnect();
          }
          Connections {
            target: deviceButton.modelData
            function onStateChanged() {
              // Quickshell exposes failure through a return to the old state,
              // not an error signal. Keep feedback local to the requested row.
              if (!deviceButton.busy && deviceButton.requested !== -1) {
                deviceButton.failure = deviceButton.modelData.connected === !!deviceButton.requested ? "" : deviceButton.requested ? "Connection failed" : "Disconnect failed";
                deviceButton.requested = -1;
              }
            }
            function onConnectedChanged() { deviceButton.failure = ""; }
          }
          contentItem: RowLayout {
            spacing: 8
            BluetoothLabel {
              text: deviceButton.modelData.name || deviceButton.modelData.address
              Layout.fillWidth: true
              color: deviceButton.modelData.connected ? Theme.colors.base0D : Theme.headingText
            }
            BluetoothLabel {
              text: deviceButton.stateText
              font.pixelSize: @FONT_SIZE@ - 2
              color: deviceButton.failure ? Theme.colors.base08 : Theme.mutedText
            }
          }
        }
      }
    }
  }
  BluetoothButton {
    objectName: "bluetoothAdvanced"
    visible: root.expanded
    Layout.fillWidth: true
    implicitHeight: 30
    onClicked: root.advancedRequested()
    contentItem: BluetoothLabel { text: "More Bluetooth settings..."; color: Theme.mutedText }
    background: Rectangle { color: "transparent" }
  }
}
