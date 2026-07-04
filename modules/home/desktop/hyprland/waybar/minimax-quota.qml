import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
  id: root

  property bool open: false
  property var data: ({ ok: false, status: "idle", title: "MiniMax quota", message: "Open the popup to refresh quota data.", interval: {}, weekly: {} })

  readonly property string icon: "@ICON@"
  readonly property string base00: "@BASE00@"
  readonly property string base01: "@BASE01@"
  readonly property string base02: "@BASE02@"
  readonly property string base03: "@BASE03@"
  readonly property string base04: "@BASE04@"
  readonly property string base05: "@BASE05@"
  readonly property string base06: "@BASE06@"
  readonly property string base07: "@BASE07@"
  readonly property string base08: "@BASE08@"
  readonly property string base09: "@BASE09@"
  readonly property string base0B: "@BASE0B@"
  readonly property string base0D: "@BASE0D@"

  function alpha(hex, opacity) {
    return "#" + opacity + String(hex).replace("#", "");
  }

  function clampPercent(value) {
    var number = Number(value);
    if (isNaN(number)) return 0;
    return Math.max(0, Math.min(100, number));
  }

  function statusColor(status) {
    var value = String(status || "");
    if (value === "critical" || value === "exhausted" || value === "error") return base08;
    if (value === "warning") return base09;
    if (value === "ok" || value === "normal" || value === "unlimited") return base0B;
    return base0D;
  }

  function show() {
    open = true;
    focusTimer.start();
    refresh();
  }

  function hide() {
    open = false;
  }

  function toggle() {
    if (open) {
      hide();
    } else {
      show();
    }
  }

  function refresh() {
    if (!fetch.running) fetch.running = true;
  }

  function applyData(text) {
    try {
      data = JSON.parse(text);
    } catch (error) {
      data = {
        ok: false,
        status: "parse",
        title: "MiniMax quota parse error",
        message: String(error),
        interval: {},
        weekly: {}
      };
    }
  }

  IpcHandler {
    target: "minimax-quota"

    function toggle(): void { root.toggle(); }
    function show(): void { root.show(); }
    function hide(): void { root.hide(); }
    function refresh(): void { root.refresh(); }
  }

  Process {
    id: fetch
    command: ["@DATA_COMMAND@"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: root.applyData(this.text)
    }
  }

  Timer {
    interval: @INTERVAL_MS@
    repeat: true
    running: root.open
    onTriggered: root.refresh()
  }

  Timer {
    id: focusTimer
    interval: 1
    repeat: false
    onTriggered: frame.forceActiveFocus()
  }

  PanelWindow {
    id: popup
    visible: root.open
    color: "transparent"
    implicitWidth: 460
    implicitHeight: 380
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
    WlrLayershell.namespace: "quickshell-minimax-quota"
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

      Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        Row {
          width: parent.width
          spacing: 12

          Text {
            width: 34
            color: root.statusColor(root.data.class)
            text: root.icon
            font.pixelSize: 24
          }

          Column {
            width: parent.width - 34 - closeButton.width - parent.spacing * 2
            spacing: 4

            Text {
              width: parent.width
              color: root.base07
              text: "MiniMax quota"
              font.pixelSize: 22
              font.bold: true
            }

            Text {
              width: parent.width
              color: root.base04
              text: root.data.ok === true
                ? "model " + (root.data.modelName || "general") + " - updated " + (root.data.generatedAtText || "n/a")
                : (root.data.status || "idle")
              elide: Text.ElideRight
              font.pixelSize: 12
            }
          }

          Rectangle {
            id: closeButton
            width: 30
            height: 30
            radius: 15
            color: closeArea.containsMouse ? root.alpha(root.base08, "44") : root.alpha(root.base05, "22")

            Text {
              anchors.centerIn: parent
              color: root.base06
              text: "x"
              font.pixelSize: 16
              font.bold: true
            }

            MouseArea {
              id: closeArea
              anchors.fill: parent
              hoverEnabled: true
              onClicked: root.hide()
            }
          }
        }

        Row {
          width: parent.width
          spacing: 12
          visible: root.data.ok === true

          MetricCard {
            width: (parent.width - parent.spacing) / 2
            title: "5 hour"
            metric: root.data.interval || ({})
            accent: root.statusColor(root.data.class)
          }

          MetricCard {
            width: (parent.width - parent.spacing) / 2
            title: "weekly"
            metric: root.data.weekly || ({})
            accent: root.statusColor(root.data.class)
          }
        }

        Rectangle {
          width: parent.width
          implicitHeight: detailsContent.implicitHeight + 28
          radius: 16
          color: root.alpha(root.base01, "dd")
          border.color: root.alpha(root.base05, "22")
          visible: root.data.ok === true

          Column {
            id: detailsContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 9

            Text {
              width: parent.width
              color: root.base06
              text: "Plan details"
              font.pixelSize: 15
              font.bold: true
            }

            DetailRow { label: "5h status"; value: (root.data.interval ? root.data.interval.statusText : "n/a") + ", reset " + (root.data.interval ? root.data.interval.resetText : "n/a") }
            DetailRow { label: "weekly status"; value: (root.data.weekly ? root.data.weekly.statusText : "n/a") + ", reset " + (root.data.weekly ? root.data.weekly.resetText : "n/a") }
            DetailRow { label: "api"; value: (root.data.baseStatus || 0) + ": " + (root.data.baseMessage || "success") }
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
              text: root.data.title || "MiniMax quota unavailable"
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

  component ProgressBar: Rectangle {
    property real value: 0
    property string accent: root.base0B

    height: 8
    radius: 4
    color: root.alpha(root.base05, "22")

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: parent.width * root.clampPercent(parent.value) / 100
      radius: parent.radius
      color: parent.accent
    }
  }

  component MetricCard: Rectangle {
    id: card
    property string title: "quota"
    property var metric: ({})
    property string accent: root.base0B

    implicitHeight: 126
    radius: 16
    color: root.alpha(root.base01, "dd")
    border.color: root.alpha(root.base05, "22")

    Column {
      anchors.fill: parent
      anchors.margins: 14
      spacing: 9

      Text {
        width: parent.width
        color: root.base04
        text: card.title
        font.pixelSize: 12
        font.bold: true
      }

      Text {
        width: parent.width
        color: root.base07
        text: card.metric.percentText || "n/a"
        font.pixelSize: 30
        font.bold: true
      }

      ProgressBar {
        width: parent.width
        value: card.metric.percent || 0
        accent: card.accent
      }

      Text {
        width: parent.width
        color: root.base05
        text: "reset in " + (card.metric.remainsText || "n/a")
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
      color: root.base04
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
