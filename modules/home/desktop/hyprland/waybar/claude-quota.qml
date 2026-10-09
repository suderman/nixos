import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
  id: root

  property bool open: false
  property bool pinned: false
  property bool panelHovered: false
  property var data: ({ ok: false, status: "idle", title: "Claude quota", message: "Open the popup to refresh quota data." })

  readonly property string icon: "@ICON@"
  readonly property string base00: Theme.colors.base00
  readonly property string base01: Theme.colors.base01
  readonly property string base05: Theme.colors.base05
  readonly property string base08: Theme.colors.base08
  readonly property string base09: Theme.colors.base09
  readonly property string base0B: Theme.colors.base0B
  readonly property string base0D: Theme.colors.base0D

  function alpha(hex, opacity) {
    return "#" + opacity + String(hex).replace("#", "");
  }

  function clampPercent(value) {
    var number = Number(value);
    if (isNaN(number)) return 0;
    return Math.max(0, Math.min(100, number));
  }

  function classColor(value) {
    if (value === "critical") return base08;
    if (value === "warning") return base09;
    if (value === "ok") return base0B;
    return base0D;
  }

  // Colour a window by how much of it is left.
  function remainingColor(percent) {
    var value = Number(percent);
    if (isNaN(value)) return base0D;
    if (value <= 10) return base08;
    if (value <= 30) return base09;
    return base0B;
  }

  function show() {
    open = true;
    dismissTimer.stop();
    focusTimer.start();
    refresh();
  }

  function dismiss() {
    open = false;
    panelHovered = false;
    dismissTimer.stop();
  }

  function hide() {
    pinned = false;
    dismiss();
  }

  function toggle() {
    if (open) hide();
    else show();
  }

  function togglePinned() {
    pinned = !pinned;
    if (pinned) dismissTimer.stop();
    else scheduleDismiss();
  }

  function scheduleDismiss() {
    if (!open || pinned || panelHovered) {
      dismissTimer.stop();
      return;
    }
    dismissTimer.restart();
  }

  function refresh() {
    if (!fetch.running) fetch.running = true;
  }

  function applyData(text) {
    try {
      data = JSON.parse(text);
    } catch (error) {
      data = { ok: false, status: "parse", title: "Claude quota parse error", message: String(error) };
    }
  }

  IpcHandler {
    target: "claude-quota"

    function toggle(): void { root.toggle(); }
    function show(): void { root.show(); }
    function hide(): void { root.hide(); }
    function refresh(): void { root.refresh(); }
  }

  Process {
    id: fetch
    command: ["@DATA_COMMAND@", "popup"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: root.applyData(this.text)
    }
  }

  Process {
    id: openUsage
    command: ["@OPEN_COMMAND@", "@USAGE_URL@"]
    running: false
  }

  Timer {
    interval: @INTERVAL_MS@
    repeat: true
    running: root.open
    onTriggered: root.refresh()
  }

  Timer {
    id: dismissTimer
    interval: 300
    repeat: false
    onTriggered: {
      if (!root.pinned && !root.panelHovered) root.dismiss();
    }
  }

  Timer {
    id: focusTimer
    interval: 1
    repeat: false
    onTriggered: frame.forceActiveFocus()
  }

  PanelWindow {
    visible: root.open
    color: "transparent"
    implicitWidth: 460
    implicitHeight: content.implicitHeight + 36
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    anchors {
      top: true
      right: true
    }

    margins {
      top: 38
      right: 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-claude-quota"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Rectangle {
      id: frame
      anchors.fill: parent
      color: root.alpha(root.base00, "f0")
      radius: 18
      border.color: root.alpha(root.base05, "33")
      border.width: 1
      focus: true

      Keys.onEscapePressed: root.hide()

      HoverHandler {
        onHoveredChanged: {
          root.panelHovered = hovered;
          root.scheduleDismiss();
        }
      }

      Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 18
        spacing: 14

        Row {
          width: parent.width
          spacing: 12

          Text {
            width: 34
            color: root.classColor(root.data.class)
            text: root.icon
            font.pixelSize: 24
          }

          Column {
            width: parent.width - 34 - usageButton.width - pinButton.width - parent.spacing * 3
            spacing: 4

            Text {
              width: parent.width
              color: Theme.headingText
              text: "Claude quota"
              font.pixelSize: 22
              font.bold: true
            }

            Text {
              width: parent.width
              color: Theme.mutedText
              text: root.data.ok === true ? root.data.plan + " - updated " + root.data.updatedText + (root.data.staleText ? " (" + root.data.staleText + ")" : "") : (root.data.status || "idle")
              elide: Text.ElideRight
              font.pixelSize: 12
            }
          }

          Pill {
            id: usageButton
            label: "usage"
            onClicked: openUsage.running = true
          }

          Pill {
            id: pinButton
            label: root.pinned ? "pinned" : "pin"
            active: root.pinned
            onClicked: root.togglePinned()
          }
        }

        Row {
          width: parent.width
          spacing: 12
          visible: root.data.ok === true

          MetricCard {
            width: (parent.width - parent.spacing) / 2
            title: "5 hour"
            metric: root.data.session || ({})
          }

          MetricCard {
            width: (parent.width - parent.spacing) / 2
            title: "weekly"
            metric: root.data.weekly || ({})
          }
        }

        Rectangle {
          width: parent.width
          implicitHeight: details.implicitHeight + 28
          radius: 16
          color: root.alpha(root.base01, "dd")
          border.color: root.alpha(root.base05, "22")
          visible: root.data.ok === true

          Column {
            id: details
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 9

            Repeater {
              model: root.data.models || []

              DetailRow {
                required property var modelData
                label: modelData.name + " week"
                value: modelData.metric.percentText + " left, reset " + modelData.metric.resetText
              }
            }

            DetailRow {
              visible: !!root.data.extraText
              label: "extra usage"
              value: root.data.extraText || ""
            }

            DetailRow {
              label: "token"
              value: root.data.tokenText || "n/a"
            }
          }
        }

        Rectangle {
          width: parent.width
          implicitHeight: errorContent.implicitHeight + 28
          radius: 16
          color: root.alpha(root.base01, "dd")
          border.color: root.alpha(root.base08, "55")
          visible: root.data.ok !== true

          Column {
            id: errorContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 8

            Text {
              width: parent.width
              color: root.base08
              text: root.data.title || "Claude quota unavailable"
              font.pixelSize: 16
              font.bold: true
            }

            Text {
              width: parent.width
              color: root.base05
              text: root.data.message || "No quota data available."
              wrapMode: Text.WordWrap
              font.pixelSize: 13
            }
          }
        }
      }
    }
  }

  component Pill: Rectangle {
    id: pill
    property string label: ""
    property bool active: false
    signal clicked()

    width: 58
    height: 30
    radius: 15
    color: active ? root.base0D : (area.containsMouse ? root.alpha(root.base05, "33") : root.alpha(root.base05, "22"))

    Text {
      anchors.centerIn: parent
      color: pill.active ? Theme.selectedText : Theme.detailText
      text: pill.label
      font.pixelSize: 11
      font.bold: true
    }

    MouseArea {
      id: area
      anchors.fill: parent
      hoverEnabled: true
      onClicked: pill.clicked()
    }
  }

  // Remaining quota, with a tick where an even burn over the window would be.
  component ProgressBar: Rectangle {
    id: bar
    property real value: 0
    property var marker: null
    property string accent: root.base0B

    height: 8
    radius: 4
    color: root.alpha(root.base05, "22")

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: parent.width * root.clampPercent(bar.value) / 100
      radius: parent.radius
      color: bar.accent
    }

    Rectangle {
      visible: bar.marker !== null && bar.marker !== undefined
      x: parent.width * root.clampPercent(bar.marker) / 100 - width / 2
      y: -3
      width: 2
      height: parent.height + 6
      radius: 1
      color: root.base05
    }
  }

  component MetricCard: Rectangle {
    id: card
    property string title: ""
    property var metric: ({})

    implicitHeight: cardContent.implicitHeight + 28
    radius: 16
    color: root.alpha(root.base01, "dd")
    border.color: root.alpha(root.base05, "22")

    Column {
      id: cardContent
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 14
      spacing: 8

      Text {
        width: parent.width
        color: Theme.mutedText
        text: card.title
        font.pixelSize: 12
        font.bold: true
      }

      Text {
        width: parent.width
        color: Theme.headingText
        text: (card.metric.percentText || "n/a") + " left"
        font.pixelSize: 26
        font.bold: true
      }

      ProgressBar {
        width: parent.width
        value: card.metric.percent || 0
        marker: card.metric.paceMarker
        accent: root.remainingColor(card.metric.percent)
      }

      Text {
        width: parent.width
        color: root.base05
        text: "reset " + (card.metric.resetText || "n/a")
        elide: Text.ElideRight
        font.pixelSize: 12
      }

      Text {
        width: parent.width
        color: Theme.mutedText
        text: card.metric.resetAtText || ""
        elide: Text.ElideRight
        font.pixelSize: 12
      }

      Text {
        width: parent.width
        color: Number(card.metric.pace) < 0 ? root.base09 : root.base05
        text: "pace " + (card.metric.paceText || "n/a")
        elide: Text.ElideRight
        font.pixelSize: 12
      }
    }
  }

  component DetailRow: Row {
    property string label: ""
    property string value: ""

    width: parent.width
    spacing: 10

    Text {
      width: 94
      color: Theme.mutedText
      text: parent.label
      elide: Text.ElideRight
      font.pixelSize: 12
      font.bold: true
    }

    Text {
      width: parent.width - 94 - parent.spacing
      color: root.base05
      text: parent.value
      elide: Text.ElideRight
      font.pixelSize: 12
    }
  }
}
