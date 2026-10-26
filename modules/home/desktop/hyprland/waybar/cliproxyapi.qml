import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

Scope {
  id: root
  property bool open: false
  property bool pinned: false
  property bool panelHovered: false
  property var data: ({ providers: [], message: "Loading quota snapshot…", updatedText: "never" })

  function alpha(hex, opacity) { return "#" + opacity + String(hex).replace("#", ""); }
  function remainingColor(value) {
    if (value <= 10) return Theme.colors.base08;
    if (value <= 30) return Theme.colors.base09;
    return Theme.colors.base0B;
  }
  function refresh() { if (!fetch.running) fetch.running = true; }
  function show() {
    open = true;
    dismissTimer.stop();
    focusTimer.start();
    refresh();
  }
  function hide() {
    open = false;
    pinned = false;
    panelHovered = false;
    dismissTimer.stop();
  }
  function toggle() { if (open) hide(); else show(); }
  function scheduleDismiss() {
    if (!open || pinned || panelHovered) dismissTimer.stop();
    else dismissTimer.restart();
  }
  function applyData(text) {
    try { data = JSON.parse(text); }
    catch (error) { data = { providers: [], message: "Cannot read quota snapshot. Open management to check CLIProxyAPI.", updatedText: "never" }; }
  }

  IpcHandler {
    target: "cliproxyapi"
    function toggle(): void { root.toggle(); }
    function show(): void { root.show(); }
    function hide(): void { root.hide(); }
    function refresh(): void { root.refresh(); }
  }
  Process {
    id: fetch
    command: ["@DATA_COMMAND@", "popup"]
    stdout: StdioCollector { onStreamFinished: root.applyData(this.text) }
  }
  Process {
    id: openManagement
    command: ["@OPEN_COMMAND@", "@MANAGEMENT_URL@"]
  }
  Timer { interval: 60000; repeat: true; running: root.open; onTriggered: root.refresh() }
  Timer { id: focusTimer; interval: 1; onTriggered: frame.forceActiveFocus() }
  Timer {
    id: dismissTimer
    interval: 300
    onTriggered: { if (!root.pinned && !root.panelHovered) root.hide(); }
  }

  PanelWindow {
    id: panel
    visible: root.open
    color: "transparent"
    implicitWidth: Math.min(620, screen.width - 24)
    implicitHeight: content.implicitHeight + 36
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    anchors { top: true; right: true }
    margins { top: 38; right: 12 }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-cliproxyapi"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Rectangle {
      id: frame
      anchors.fill: parent
      radius: 18
      color: root.alpha(Theme.colors.base00, "f0")
      border.color: root.alpha(Theme.colors.base05, "33")
      border.width: 1
      focus: true
      Keys.onEscapePressed: root.hide()
      HoverHandler { onHoveredChanged: { root.panelHovered = hovered; root.scheduleDismiss(); } }

      Column {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 14

        Row {
          width: parent.width
          spacing: 12
          Column {
            width: parent.width - pinButton.width - closeButton.width - parent.spacing * 2
            spacing: 4
            Text { text: "AI quotas"; color: Theme.headingText; font.pixelSize: 22; font.bold: true }
            Text {
              text: "CLIProxyAPI · updated " + root.data.updatedText
              color: Theme.mutedText
              font.pixelSize: 12
            }
          }
          ActionButton {
            id: pinButton
            label: root.pinned ? "Unpin" : "Pin"
            active: root.pinned
            onClicked: { root.pinned = !root.pinned; root.scheduleDismiss(); }
          }
          ActionButton { id: closeButton; label: "Close"; onClicked: root.hide() }
        }

        Text {
          width: parent.width
          visible: !!root.data.message
          text: root.data.message || ""
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          color: Theme.colors.base09
          font.pixelSize: 13
        }

        Flickable {
          id: list
          width: parent.width
          height: Math.min(accountList.implicitHeight, Math.max(180, panel.screen.height - 245))
          contentWidth: width
          contentHeight: accountList.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          ScrollBar.vertical: ScrollBar {}

          Column {
            id: accountList
            width: list.width - 12
            spacing: 20
            Repeater {
              model: root.data.providers || []
              Column {
                required property var modelData
                width: accountList.width
                spacing: 8
                Row {
                  width: parent.width
                  spacing: 8
                  Text {
                    text: modelData.icon
                    color: Theme.colors.base0D
                    font.pixelSize: 18
                  }
                  Text { text: modelData.title; color: Theme.headingText; font.pixelSize: 16; font.bold: true }
                  Text {
                    text: modelData.ready + "/" + modelData.count + " accounts with allowance"
                    color: Theme.mutedText
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Text {
                  visible: modelData.count === 0
                  text: "No enrolled accounts. Add one in management."
                  color: Theme.mutedText
                  font.pixelSize: 13
                }
                Repeater {
                  model: modelData.accounts
                  Rectangle {
                    required property var modelData
                    id: accountCard
                    width: parent.width
                    implicitHeight: accountContent.implicitHeight + 24
                    radius: 12
                    color: root.alpha(Theme.colors.base01, "dd")
                    Column {
                      id: accountContent
                      anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                      spacing: 8
                      Row {
                        width: parent.width
                        spacing: 12
                        Text {
                          width: parent.width - stateText.implicitWidth - parent.spacing
                          text: accountCard.modelData.label + (accountCard.modelData.plan ? " · " + accountCard.modelData.plan : "")
                          textFormat: Text.PlainText
                          elide: Text.ElideMiddle
                          color: Theme.headingText
                          font.pixelSize: 13
                          font.bold: true
                        }
                        Text {
                          id: stateText
                          text: accountCard.modelData.status
                          color: text === "Ready" ? Theme.colors.base0B : Theme.colors.base09
                          font.pixelSize: 12
                        }
                      }
                      Repeater {
                        model: accountCard.modelData.windows
                        Column {
                          required property var modelData
                          width: accountContent.width
                          spacing: 5
                          Row {
                            width: parent.width
                            spacing: 10
                            Text { width: 115; text: modelData.name; color: Theme.detailText; font.pixelSize: 12 }
                            Text {
                              width: 68
                              text: modelData.percentText + " left"
                              color: root.remainingColor(modelData.remaining)
                              font.pixelSize: 12
                              font.bold: true
                            }
                            Text {
                              width: parent.width - 203
                              text: modelData.resetText + (modelData.resetAtText ? " · " + modelData.resetAtText : "")
                              elide: Text.ElideRight
                              color: Theme.mutedText
                              font.pixelSize: 12
                            }
                          }
                          Rectangle {
                            width: parent.width
                            height: 5
                            radius: 2
                            color: root.alpha(Theme.colors.base05, "22")
                            Rectangle {
                              height: parent.height
                              width: parent.width * modelData.remaining / 100
                              radius: 2
                              color: root.remainingColor(modelData.remaining)
                              opacity: accountCard.modelData.status === "Ready" ? 1 : 0.45
                            }
                            Rectangle {
                              visible: modelData.paceMarker !== null
                              x: parent.width * (modelData.paceMarker || 0) / 100 - 1
                              y: -2
                              width: 2
                              height: 9
                              color: Theme.detailText
                            }
                          }
                        }
                      }
                      Text {
                        width: parent.width
                        visible: accountCard.modelData.stale || accountCard.modelData.disabled || accountCard.modelData.windows.length === 0
                        text: (accountCard.modelData.error ? accountCard.modelData.error + ". " : "") + "Last quota update: " + accountCard.modelData.updatedText + "."
                        textFormat: Text.PlainText
                        wrapMode: Text.WordWrap
                        color: Theme.colors.base09
                        font.pixelSize: 12
                      }
                    }
                  }
                }
              }
            }
          }
        }

        Row {
          width: parent.width
          spacing: 10
          ActionButton { label: "Open management"; onClicked: openManagement.running = true }
          ActionButton { label: fetch.running ? "Loading…" : "Refresh"; enabled: !fetch.running; onClicked: root.refresh() }
          Text {
            text: "Ticks mark even-use pace"
            color: Theme.mutedText
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }

  component ActionButton: Rectangle {
    id: button
    property string label: ""
    property bool active: false
    signal clicked()
    implicitWidth: caption.implicitWidth + 24
    implicitHeight: 32
    radius: 16
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.5
    color: active ? Theme.colors.base0D : root.alpha(Theme.colors.base05, mouse.containsMouse ? "33" : "22")
    border.width: activeFocus ? 2 : 0
    border.color: Theme.colors.base0D
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
    Text {
      id: caption
      anchors.centerIn: parent
      text: button.label
      color: button.active ? Theme.selectedText : Theme.detailText
      font.pixelSize: 12
      font.bold: true
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: button.clicked() }
  }
}
