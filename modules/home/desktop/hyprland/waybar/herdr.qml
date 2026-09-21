import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
  id: root

  property bool open: false
  property bool pinned: false
  property bool panelHovered: false
  property var data: ({ ok: false, class: "offline", message: "Open the popup to read Herdr state.", counts: {}, agents: [] })
  readonly property var agents: data.agents || []

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
  readonly property string base0A: "@BASE0A@"
  readonly property string base0B: "@BASE0B@"
  readonly property string base0D: "@BASE0D@"

  function alpha(hex, opacity) {
    return "#" + opacity + String(hex).replace("#", "");
  }

  function statusColor(status) {
    var value = String(status || "unknown");
    if (value === "blocked") return base08;
    if (value === "done") return base0A;
    if (value === "working") return base0B;
    if (value === "idle") return base0D;
    return base04;
  }

  function statusMarker(status) {
    var value = String(status || "unknown");
    if (value === "blocked") return "!";
    if (value === "done") return "✓";
    if (value === "working") return "●";
    if (value === "idle") return "○";
    return "?";
  }

  function statusLabel(agent) {
    var label = String(agent.statusLabel || agent.status || "unknown");
    if (agent.status === "blocked" && label === "blocked") return "needs input";
    if (agent.status === "done" && label === "done") return "done unseen";
    return label.replace(/_/g, " ");
  }

  function summaryText() {
    var counts = data.counts || {};
    var parts = [];
    if (Number(counts.blocked || 0) > 0) parts.push(counts.blocked + " blocked");
    if (Number(counts.done || 0) > 0) parts.push(counts.done + " unseen done");
    if (Number(counts.working || 0) > 0) parts.push(counts.working + " working");
    if (Number(counts.idle || 0) > 0) parts.push(counts.idle + " idle");
    if (Number(counts.unknown || 0) > 0) parts.push(counts.unknown + " unknown");
    return parts.length > 0 ? parts.join(" · ") : "No detected agents";
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

  function panelEnter() {
    panelHovered = true;
    dismissTimer.stop();
  }

  function panelLeave() {
    panelHovered = false;
    scheduleDismiss();
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

  function jumpToAgent(paneId) {
    if (jump.running || !paneId) return;
    jump.command = ["@JUMP_COMMAND@", String(paneId)];
    jump.running = true;
    hide();
  }

  function applyData(text) {
    try {
      data = JSON.parse(text);
    } catch (error) {
      data = {
        ok: false,
        class: "offline",
        message: "Could not parse Herdr status: " + String(error),
        counts: {},
        agents: []
      };
    }
  }

  IpcHandler {
    target: "herdr"

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

  Process {
    id: jump
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
    id: popup
    visible: root.open
    color: "transparent"
    implicitWidth: 560
    implicitHeight: 680
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
    WlrLayershell.namespace: "quickshell-herdr"
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
          if (hovered) root.panelEnter();
          else root.panelLeave();
        }
      }

      Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        Row {
          id: header
          width: parent.width
          spacing: 12

          Text {
            width: 34
            color: root.statusColor(root.data.class)
            text: root.icon
            font.pixelSize: 24
          }

          Column {
            width: parent.width - 34 - pinButton.width - refreshButton.width - parent.spacing * 3
            spacing: 4

            Text {
              width: parent.width
              color: root.base07
              text: "Herdr agents"
              font.pixelSize: 22
              font.bold: true
            }

            Text {
              width: parent.width
              color: root.base04
              text: root.data.ok === true
                ? root.summaryText() + " · updated " + (root.data.generatedAtText || "n/a")
                : "Herdr unavailable"
              elide: Text.ElideRight
              font.pixelSize: 12
            }
          }

          Rectangle {
            id: refreshButton
            width: 34
            height: 30
            radius: 15
            color: refreshArea.containsMouse ? root.alpha(root.base05, "33") : root.alpha(root.base05, "22")

            Text {
              anchors.centerIn: parent
              color: root.base06
              text: "↻"
              font.pixelSize: 16
            }

            MouseArea {
              id: refreshArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.refresh()
            }
          }

          Rectangle {
            id: pinButton
            width: 58
            height: 30
            radius: 15
            color: root.pinned ? root.alpha(root.base0D, "66") : (pinArea.containsMouse ? root.alpha(root.base05, "33") : root.alpha(root.base05, "22"))

            Text {
              anchors.centerIn: parent
              color: root.pinned ? root.base00 : root.base06
              text: root.pinned ? "pinned" : "pin"
              font.pixelSize: 11
              font.bold: true
            }

            MouseArea {
              id: pinArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.togglePinned()
            }
          }
        }

        Rectangle {
          width: parent.width
          implicitHeight: errorText.implicitHeight + 28
          radius: 14
          color: root.alpha(root.base01, "dd")
          border.color: root.alpha(root.base08, "55")
          visible: root.data.ok !== true

          Text {
            id: errorText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            color: root.base05
            text: root.data.message || "No Herdr state available."
            wrapMode: Text.WordWrap
            font.pixelSize: 13
          }
        }

        Text {
          width: parent.width
          color: root.base04
          text: "No agents are connected to the local Herdr session."
          visible: root.data.ok === true && root.agents.length === 0
          wrapMode: Text.WordWrap
          font.pixelSize: 13
        }

        Flickable {
          id: roster
          width: parent.width
          height: parent.height - header.height - parent.spacing
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          contentWidth: width
          contentHeight: agentList.implicitHeight
          visible: root.data.ok === true && root.agents.length > 0

          Column {
            id: agentList
            width: roster.width
            spacing: 8

            Repeater {
              model: root.agents

              AgentRow {
                width: agentList.width
                agent: modelData
              }
            }
          }
        }
      }
    }
  }

  component StatusPill: Rectangle {
    property string label: "unknown"
    property string status: "unknown"

    implicitWidth: pillText.implicitWidth + 18
    implicitHeight: 24
    radius: 12
    color: root.alpha(root.statusColor(status), "22")
    border.color: root.alpha(root.statusColor(status), "aa")

    Text {
      id: pillText
      anchors.centerIn: parent
      color: root.statusColor(parent.status)
      text: parent.label
      font.pixelSize: 11
      font.bold: true
    }
  }

  component AgentRow: Rectangle {
    id: card
    property var agent: ({})

    implicitHeight: 78
    radius: 14
    color: rowArea.containsMouse ? root.alpha(root.base02, "ee") : root.alpha(root.base01, "cc")
    border.color: root.alpha(root.statusColor(agent.status), agent.status === "blocked" || agent.status === "done" ? "88" : "33")

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: 4
      radius: 2
      color: root.statusColor(card.agent.status)
    }

    Row {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 12

      Column {
        width: parent.width - statusPill.width - parent.spacing
        spacing: 4

        Text {
          width: parent.width
          color: root.base07
          text: card.agent.workspace || "workspace"
          elide: Text.ElideRight
          font.pixelSize: 15
          font.bold: true
        }

        Text {
          width: parent.width
          color: root.base05
          text: (card.agent.tab || "tab") + " · " + (card.agent.agentLabel || "agent") + " · " + (card.agent.paneId || "")
          elide: Text.ElideRight
          font.pixelSize: 12
        }

        Text {
          width: parent.width
          color: root.base04
          text: card.agent.title || card.agent.cwd || ""
          visible: text !== ""
          elide: Text.ElideMiddle
          font.pixelSize: 11
        }
      }

      StatusPill {
        id: statusPill
        label: root.statusMarker(card.agent.status) + " " + root.statusLabel(card.agent)
        status: card.agent.status || "unknown"
      }
    }

    MouseArea {
      id: rowArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.jumpToAgent(card.agent.paneId)
    }
  }
}
