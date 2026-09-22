import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
  id: root

  property bool open: false
  property bool pinned: false
  property bool panelHovered: false
  property var data: ({ ok: false, status: "idle", title: "codex-lb", message: "Open the popup to refresh quota data.", accounts: [], recentLogs: [] })
  readonly property var accounts: data.accounts || []
  readonly property var recentLogs: data.recentLogs || []
  property string accountActionMessage: ""
  property bool authPromptOpen: false
  property bool authNeedsUsername: false
  property var pendingAccount: null
  property string pendingAction: ""
  property string accountActionInput: ""

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
  readonly property string base0E: "@BASE0E@"

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
    if (value === "danger" || value === "critical" || value === "quota" || value === "quota_exceeded" || value === "error") return base08;
    if (value === "behind" || value === "warning" || value === "stale" || value === "rate_limit" || value === "rate_limited") return base09;
    if (value === "ahead" || value === "on_track" || value === "active" || value === "ok") return base0B;
    return base0D;
  }

  function statusText(status) {
    var value = String(status || "unknown");
    if (value === "ok") return "OK";
    if (value === "rate_limit") return "Rate limit";
    if (value === "quota") return "Quota";
    if (value === "error") return "Error";
    return value.replace(/_/g, " ");
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
    authPromptOpen = false;
    authNeedsUsername = false;
    pendingAccount = null;
    pendingAction = "";
    accountActionInput = "";
    usernameInput.text = "";
    passwordInput.text = "";
    dismiss();
  }

  function toggle() {
    if (open) {
      hide();
    } else {
      show();
    }
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
    if (pinned) {
      dismissTimer.stop();
    } else {
      scheduleDismiss();
    }
  }

  function scheduleDismiss() {
    if (!open || pinned || authPromptOpen || accountAction.running) {
      dismissTimer.stop();
      return;
    }

    if (panelHovered) {
      dismissTimer.stop();
      return;
    }

    dismissTimer.restart();
  }

  function refresh() {
    if (!fetch.running) fetch.running = true;
  }

  function openDashboard() {
    if (!openUrl.running && (data.url || "") !== "") openUrl.running = true;
  }

  function startAccountAction(authenticate) {
    if (accountAction.running || !pendingAccount || !pendingAccount.id) return;
    accountAction.command = [
      "@ACCOUNT_COMMAND@",
      String(pendingAccount.id),
      pendingAction,
      authenticate ? "login" : "try"
    ];
    if (!authenticate) accountActionInput = "";
    dismissTimer.stop();
    accountAction.running = true;
  }

  function toggleAccount(account) {
    if (accountAction.running || authPromptOpen || !account.id) return;
    var status = String(account.status || "");
    if (status !== "active" && status !== "paused") return;
    pendingAccount = account;
    pendingAction = status === "paused" ? "resume" : "pause";
    accountActionMessage = pendingAction === "resume" ? "Resuming " + account.name + "…" : "Pausing " + account.name + "…";
    startAccountAction(false);
  }

  function submitAccountAuth() {
    if (accountAction.running) return;
    var password = passwordInput.text;
    var username = usernameInput.text;
    if (password === "") {
      accountActionMessage = "Dashboard password is required.";
      passwordInput.forceActiveFocus();
      return;
    }
    if (authNeedsUsername && username === "") {
      accountActionMessage = "Dashboard username is required.";
      usernameInput.forceActiveFocus();
      return;
    }

    accountActionMessage = "Signing in to update " + pendingAccount.name + "…";
    accountActionInput = JSON.stringify({ username: username, password: password });
    passwordInput.text = "";
    startAccountAction(true);
  }

  function cancelAccountAuth() {
    if (accountAction.running) return;
    authPromptOpen = false;
    authNeedsUsername = false;
    pendingAccount = null;
    pendingAction = "";
    accountActionInput = "";
    usernameInput.text = "";
    passwordInput.text = "";
    accountActionMessage = "Account change cancelled.";
    scheduleDismiss();
  }

  function applyAccountAction(text) {
    try {
      var result = JSON.parse(text);
      accountActionMessage = result.message || "Account updated.";
      if (result.authRequired === true) {
        authNeedsUsername = result.usernameRequired === true;
        authPromptOpen = true;
        passwordInput.text = "";
        Qt.callLater(function() {
          if (root.authNeedsUsername) usernameInput.forceActiveFocus();
          else passwordInput.forceActiveFocus();
        });
        return;
      }

      authPromptOpen = false;
      authNeedsUsername = false;
      pendingAccount = null;
      pendingAction = "";
      accountActionInput = "";
      usernameInput.text = "";
      passwordInput.text = "";
      if (result.ok === true) refresh();
    } catch (error) {
      authPromptOpen = false;
      accountActionMessage = "Could not read account action result: " + String(error);
    }
  }

  function applyData(text) {
    try {
      data = JSON.parse(text);
    } catch (error) {
      data = {
        ok: false,
        status: "parse",
        title: "codex-lb parse error",
        message: String(error),
        accounts: [],
        recentLogs: []
      };
    }
  }

  IpcHandler {
    target: "codex-lb"

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
    id: openUrl
    command: ["@OPEN_COMMAND@", root.data.url || ""]
    running: false
  }

  Process {
    id: accountAction
    running: false
    stdinEnabled: true

    onStarted: {
      if (root.accountActionInput !== "") {
        write(root.accountActionInput + "\n");
        root.accountActionInput = "";
      }
    }

    stdout: StdioCollector {
      onStreamFinished: root.applyAccountAction(this.text)
    }
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
    implicitWidth: 700
    implicitHeight: 980
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
    WlrLayershell.namespace: "quickshell-codex-lb"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Rectangle {
      id: frame
      anchors.fill: parent
      color: root.alpha(root.base00, "f0")
      radius: 18
      border.color: root.alpha(root.base05, "33")
      border.width: 1
      focus: true

      Keys.onEscapePressed: {
        if (root.authPromptOpen) root.cancelAccountAuth();
        else root.hide();
      }

      HoverHandler {
        onHoveredChanged: {
          if (hovered) root.panelEnter();
          else root.panelLeave();
        }
      }

      Flickable {
        id: scroller
        anchors.fill: parent
        anchors.margins: 18
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: content.implicitHeight

        Column {
          id: content
          width: scroller.width
          spacing: 14

          Row {
            width: parent.width
            spacing: 12

            Column {
              width: parent.width - pinButton.width - parent.spacing
              spacing: 4

              Text {
                width: parent.width
                color: root.base07
                text: "OpenAI Codex quota"
                font.pixelSize: 22
                font.bold: true
              }

              Row {
                width: parent.width
                spacing: 8

                Text {
                  id: urlLabel
                  width: Math.min(implicitWidth, parent.width * 0.5)
                  color: urlArea.containsMouse ? root.base0D : root.base04
                  text: root.data.url || ""
                  elide: Text.ElideRight
                  font.pixelSize: 12
                  font.underline: urlArea.containsMouse

                  MouseArea {
                    id: urlArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.openDashboard()
                  }
                }

                Text {
                  width: parent.width - urlLabel.width - parent.spacing
                  color: root.base04
                  text: "last sync " + (root.data.lastSyncText || "n/a")
                  elide: Text.ElideRight
                  font.pixelSize: 12
                }
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
                onClicked: root.togglePinned()
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
              metric: root.data.primary || ({})
              accent: root.statusColor(root.data.class)
            }

            MetricCard {
              width: (parent.width - parent.spacing) / 2
              title: "weekly"
              metric: root.data.secondary || ({})
              accent: root.statusColor(root.data.pace ? root.data.pace.status : root.data.class)
            }
          }

          Rectangle {
            width: parent.width
            implicitHeight: 116
            radius: 16
            color: root.alpha(root.base01, "dd")
            border.color: root.alpha(root.base05, "22")
            visible: root.data.ok === true

            Column {
              anchors.fill: parent
              anchors.margins: 14
              spacing: 10

              Row {
                width: parent.width
                spacing: 10

                Text {
                  width: parent.width - pacePill.width - parent.spacing
                  color: root.base07
                  text: "Weekly pace"
                  font.pixelSize: 16
                  font.bold: true
                }

                Pill {
                  id: pacePill
                  label: root.statusText(root.data.pace ? root.data.pace.status : "unknown")
                  accent: root.statusColor(root.data.pace ? root.data.pace.status : "unknown")
                }
              }

              Row {
                width: parent.width
                spacing: 12

                PaceStat { width: (parent.width - 24) / 3; label: "delta"; value: root.data.pace ? root.data.pace.deltaText : "n/a" }
                PaceStat { width: (parent.width - 24) / 3; label: "actual used"; value: root.data.pace ? root.data.pace.actualUsedText : "n/a" }
                PaceStat { width: (parent.width - 24) / 3; label: "scheduled"; value: root.data.pace ? root.data.pace.scheduledUsedText : "n/a" }
              }

              Text {
                width: parent.width
                color: root.base04
                text: root.data.pace ? root.data.pace.summaryText : ""
                elide: Text.ElideRight
                font.pixelSize: 12
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
                text: root.data.title || "codex-lb unavailable"
                font.pixelSize: 16
                font.bold: true
              }

              Text {
                width: parent.width
                color: root.base05
                text: root.data.message || "No data available."
                wrapMode: Text.WordWrap
                font.pixelSize: 13
              }
            }
          }

          Row {
            width: parent.width
            spacing: 10
            visible: root.data.ok === true && root.accounts.length > 0

            Text {
              width: root.accountActionMessage === "" ? parent.width : Math.min(100, parent.width)
              color: root.base06
              text: "Accounts"
              font.pixelSize: 16
              font.bold: true
            }

            Text {
              width: parent.width - 100 - parent.spacing
              color: root.base04
              text: root.accountActionMessage
              horizontalAlignment: Text.AlignRight
              elide: Text.ElideRight
              font.pixelSize: 11
              visible: root.accountActionMessage !== ""
            }
          }

          Grid {
            id: accountGrid
            width: parent.width
            columns: 2
            columnSpacing: 10
            rowSpacing: 10
            visible: root.data.ok === true

            Repeater {
              model: root.accounts

              AccountCard {
                width: (accountGrid.width - accountGrid.columnSpacing) / 2
                account: modelData
              }
            }
          }

          Rectangle {
            width: parent.width
            height: 270
            radius: 16
            color: root.alpha(root.base01, "dd")
            border.color: root.alpha(root.data.latestLogNonOk ? root.base08 : root.base05, root.data.latestLogNonOk ? "88" : "22")
            visible: root.data.ok === true

            Column {
              anchors.fill: parent
              anchors.margins: 14
              spacing: 10

              Row {
                id: logsHeader
                width: parent.width
                spacing: 10

                Text {
                  width: parent.width - latestLogPill.width - parent.spacing
                  color: root.base06
                  text: "Recent logs"
                  font.pixelSize: 16
                  font.bold: true
                }

                Pill {
                  id: latestLogPill
                  label: root.statusText(root.data.latestLogStatus || "unknown")
                  accent: root.statusColor(root.data.latestLogStatus || "unknown")
                }
              }

              Text {
                width: parent.width
                color: root.base04
                text: "No request logs returned."
                visible: root.recentLogs.length === 0
                font.pixelSize: 12
              }

              Flickable {
                id: logScroller
                width: parent.width
                height: parent.height - logsHeader.height - parent.spacing
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: logList.implicitHeight
                visible: root.recentLogs.length > 0

                Column {
                  id: logList
                  width: logScroller.width
                  spacing: 8

                  Repeater {
                    model: root.recentLogs

                    LogRow {
                      width: logList.width
                      log: modelData
                    }
                  }
                }
              }
            }
          }
        }
      }

      Rectangle {
        anchors.fill: parent
        visible: root.authPromptOpen
        z: 10
        color: root.alpha(root.base00, "bb")

        MouseArea {
          anchors.fill: parent
        }

        Rectangle {
          id: authDialog
          anchors.centerIn: parent
          width: parent.width - 100
          height: authContent.implicitHeight + 32
          radius: 16
          color: root.base01
          border.color: root.alpha(root.base0D, "88")
          border.width: 1

          Column {
            id: authContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 10

            Text {
              width: parent.width
              color: root.base07
              text: "Dashboard login required"
              font.pixelSize: 16
              font.bold: true
            }

            Text {
              width: parent.width
              color: root.base04
              text: "Authenticate once to " + root.pendingAction + " " + (root.pendingAccount ? root.pendingAccount.name : "this account") + "."
              wrapMode: Text.WordWrap
              font.pixelSize: 12
            }

            Text {
              width: parent.width
              color: root.base05
              text: "Username"
              visible: root.authNeedsUsername
              font.pixelSize: 11
            }

            Rectangle {
              width: parent.width
              height: 38
              radius: 8
              color: root.base00
              border.color: usernameInput.activeFocus ? root.base0D : root.alpha(root.base05, "44")
              visible: root.authNeedsUsername

              TextInput {
                id: usernameInput
                anchors.fill: parent
                anchors.margins: 10
                color: root.base07
                selectionColor: root.base0D
                selectedTextColor: root.base00
                clip: true
                font.pixelSize: 13
                onAccepted: passwordInput.forceActiveFocus()
              }
            }

            Text {
              width: parent.width
              color: root.base05
              text: "Dashboard password"
              font.pixelSize: 11
            }

            Rectangle {
              width: parent.width
              height: 38
              radius: 8
              color: root.base00
              border.color: passwordInput.activeFocus ? root.base0D : root.alpha(root.base05, "44")

              TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.margins: 10
                color: root.base07
                selectionColor: root.base0D
                selectedTextColor: root.base00
                echoMode: TextInput.Password
                clip: true
                font.pixelSize: 13
                onAccepted: root.submitAccountAuth()
              }
            }

            Row {
              width: parent.width
              spacing: 10

              Rectangle {
                width: (parent.width - parent.spacing) / 2
                height: 36
                radius: 8
                color: cancelAuthArea.containsMouse ? root.alpha(root.base05, "33") : root.alpha(root.base05, "22")

                Text {
                  anchors.centerIn: parent
                  color: root.base06
                  text: "Cancel"
                  font.pixelSize: 12
                  font.bold: true
                }

                MouseArea {
                  id: cancelAuthArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  enabled: !accountAction.running
                  onClicked: root.cancelAccountAuth()
                }
              }

              Rectangle {
                width: (parent.width - parent.spacing) / 2
                height: 36
                radius: 8
                color: accountAction.running ? root.alpha(root.base0D, "44") : (submitAuthArea.containsMouse ? root.base0D : root.alpha(root.base0D, "cc"))

                Text {
                  anchors.centerIn: parent
                  color: root.base00
                  text: accountAction.running ? "Working…" : "Continue"
                  font.pixelSize: 12
                  font.bold: true
                }

                MouseArea {
                  id: submitAuthArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  enabled: !accountAction.running
                  onClicked: root.submitAccountAuth()
                }
              }
            }
          }
        }
      }
    }
  }

  component Pill: Rectangle {
    property string label: "unknown"
    property string accent: root.base0D

    implicitWidth: pillText.implicitWidth + 18
    implicitHeight: 24
    radius: 12
    color: root.alpha(accent, "22")
    border.color: root.alpha(accent, "aa")

    Text {
      id: pillText
      anchors.centerIn: parent
      color: parent.accent
      text: parent.label
      font.pixelSize: 11
      font.bold: true
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
        text: title
        font.pixelSize: 12
        font.bold: true
      }

      Row {
        width: parent.width

        Text {
          width: parent.width / 2
          color: root.base07
          text: metric.percentText || "n/a"
          font.pixelSize: 26
          font.bold: true
        }

        Text {
          width: parent.width / 2
          color: root.base04
          text: "reset " + (metric.resetText || "n/a")
          horizontalAlignment: Text.AlignRight
          elide: Text.ElideRight
          font.pixelSize: 11
        }
      }

      ProgressBar {
        width: parent.width
        value: metric.percent || 0
        accent: parent.parent.accent
      }

      Text {
        width: parent.width
        color: root.base05
        text: (metric.creditsText || "n/a") + " remaining"
        elide: Text.ElideRight
        font.pixelSize: 12
      }
    }
  }

  component PaceStat: Column {
    property string label: ""
    property string value: "n/a"

    spacing: 3

    Text {
      width: parent.width
      color: root.base04
      text: parent.label
      elide: Text.ElideRight
      font.pixelSize: 11
    }

    Text {
      width: parent.width
      color: root.base07
      text: parent.value
      elide: Text.ElideRight
      font.pixelSize: 16
      font.bold: true
    }
  }

  component QuotaLine: Column {
    property string label: "quota"
    property var metric: ({})
    property string accent: root.base0B

    spacing: 5

    Row {
      width: parent.width

      Text {
        width: 34
        color: root.base04
        text: parent.parent.label
        font.pixelSize: 12
        font.bold: true
      }

      Text {
        width: parent.width - 34
        color: root.base05
        text: (parent.parent.metric.percentText || "n/a") + ", " + (parent.parent.metric.creditsText || "n/a") + ", reset " + (parent.parent.metric.resetText || "n/a")
        elide: Text.ElideRight
        font.pixelSize: 12
      }
    }

    ProgressBar {
      width: parent.width
      value: parent.metric.percent || 0
      accent: parent.accent
    }
  }

  component AccountCard: Rectangle {
    property var account: ({})
    readonly property bool actionable: account.status === "active" || account.status === "paused"

    implicitHeight: accountContent.implicitHeight + 28
    radius: 16
    color: accountArea.containsMouse && actionable ? root.alpha(root.base02, "dd") : root.alpha(root.base01, "cc")
    border.color: root.alpha(root.base05, accountArea.containsMouse && actionable ? "66" : "22")

    Column {
      id: accountContent
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 14
      spacing: 10

      Row {
        width: parent.width
        spacing: 10

        Column {
          width: parent.width - accountPill.width - parent.spacing
          spacing: 3

          Text {
            width: parent.width
            color: root.base07
            text: account.name || "account"
            elide: Text.ElideRight
            font.pixelSize: 15
            font.bold: true
          }

          Text {
            width: parent.width
            color: root.base04
            text: (
              (account.plan || "plan unknown")
              + " · "
              + (account.resetCredits === null || account.resetCredits === undefined ? "n/a" : account.resetCredits)
              + " resets · "
              + (account.resetCreditExpiryText || "n/a")
            )
            elide: Text.ElideRight
            font.pixelSize: 11
          }
        }

        Pill {
          id: accountPill
          label: root.statusText(account.status)
          accent: root.statusColor(account.status)
        }
      }

      QuotaLine {
        width: parent.width
        label: "5h"
        metric: account.primary || ({})
        accent: root.statusColor(account.status)
      }

      QuotaLine {
        width: parent.width
        label: "7d"
        metric: account.secondary || ({})
        accent: root.base0E
      }

    }

    MouseArea {
      id: accountArea
      anchors.fill: parent
      enabled: parent.actionable
      hoverEnabled: true
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: root.toggleAccount(parent.account)
    }
  }

  component LogRow: Rectangle {
    property var log: ({})

    implicitHeight: logContent.implicitHeight + 16
    radius: 12
    color: root.alpha(root.base00, "66")
    border.color: root.alpha(root.statusColor(log.status), log.status === "ok" ? "22" : "88")

    Column {
      id: logContent
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 8
      spacing: 6

      Row {
        width: parent.width
        spacing: 10

        Column {
          width: 82
          spacing: 2

          Text {
            width: parent.width
            color: root.base06
            text: log.timeText || "--"
            elide: Text.ElideRight
            font.pixelSize: 12
            font.bold: true
          }

          Text {
            width: parent.width
            color: root.base04
            text: log.dateText || "--"
            elide: Text.ElideRight
            font.pixelSize: 10
          }
        }

        Text {
          width: 92
          color: root.base05
          text: log.account || "Unassigned"
          elide: Text.ElideRight
          font.pixelSize: 12
        }

        Text {
          width: parent.width - 82 - 92 - 70 - 58 - logStatusPill.width - parent.spacing * 5
          color: root.base06
          text: log.model || "--"
          elide: Text.ElideRight
          font.pixelSize: 12
          font.family: "monospace"
        }

        Text {
          width: 70
          color: root.base05
          text: log.tokensText || "-- tok"
          horizontalAlignment: Text.AlignRight
          elide: Text.ElideRight
          font.pixelSize: 11
          font.family: "monospace"
        }

        Text {
          width: 58
          color: root.base05
          text: log.costText || "$--"
          horizontalAlignment: Text.AlignRight
          elide: Text.ElideRight
          font.pixelSize: 11
          font.family: "monospace"
        }

        Pill {
          id: logStatusPill
          label: root.statusText(log.status)
          accent: root.statusColor(log.status)
        }
      }

      Text {
        width: parent.width
        color: root.base04
        text: ((log.errorCode || "") !== "" ? log.errorCode + ": " : "") + (log.errorMessage || "")
        visible: (log.status || "ok") !== "ok" && text !== ""
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        font.pixelSize: 11
      }
    }
  }
}
