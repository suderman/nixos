import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Scope {
  id: root
  property string image: "volume_medium"
  property real progress: 0
  property bool open: false
  property var targetScreen: null
  property int timeout: 1000
  readonly property bool muted: image.endsWith("_muted")
  readonly property string kind: image.startsWith("mic_") ? "Microphone" : image.startsWith("brightness_") ? "Brightness" : "Volume"
  readonly property string icon: image.startsWith("mic_") ? (muted ? "󰍭" : "󰍬") : image.startsWith("brightness_") ? "󰃠" : muted ? "󰝟" : "󰕾"

  function show(image: string, progress: real, monitor: int): void {
    if (!/^(volume_(muted|low|medium|high)|mic_(muted|unmuted)|brightness_(low|medium|high))$/.test(image) || !Number.isFinite(progress) || monitor < -1)
      return;
    const screens = Quickshell.screens;
    const focused = Hyprland.focusedMonitor;
    const screen = monitor >= 0 ? screens[monitor] : (screens.find(screen => screen.name === focused?.name) || screens[0]);
    if (!screen) return;
    root.targetScreen = screen;
    root.image = image;
    root.progress = Math.max(0, Math.min(1, progress));
    root.open = true;
    dismiss.restart();
  }

  IpcHandler {
    target: "media-osd"
    // "show" is also a CLI subcommand and is parsed as one before arguments.
    function display(image: string, progress: real, monitor: int): void { root.show(image, progress, monitor); }
  }

  Timer {
    id: dismiss
    interval: root.timeout
    onTriggered: root.open = false
  }

  PanelWindow {
    id: window
    visible: root.open
    screen: root.targetScreen
    color: "transparent"
    implicitWidth: 320
    implicitHeight: 96
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-media-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: Qt.alpha(Theme.colors.base00, 0.94)
      radius: 18
      border.color: Qt.alpha(Theme.colors.base05, 0.2)
      border.width: 1

      Text {
        x: 24
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: root.muted ? Theme.colors.base08 : Theme.headingText
        font.family: "Symbols Nerd Font Mono"
        font.pixelSize: 32
      }
      Text {
        x: 80
        y: 20
        text: root.kind + (root.muted ? " muted" : "")
        color: Theme.headingText
        font.family: @FONT@
        font.pointSize: @FONT_SIZE@
      }
      Rectangle {
        x: 80
        y: 56
        width: 216
        height: 8
        radius: 4
        color: Theme.colors.base02
        Rectangle {
          width: parent.width * root.progress
          height: parent.height
          radius: 4
          color: root.muted ? Theme.colors.base08 : Theme.colors.base0D
        }
      }
    }
  }
}
