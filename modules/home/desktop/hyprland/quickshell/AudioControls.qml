import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
  id: root
  spacing: 8
  signal advancedRequested()
  property bool expanded: false
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property bool sinkReady: !!sink?.ready && !!sink?.audio
  readonly property bool sourceReady: !!source?.ready && !!source?.audio
  readonly property var outputs: Pipewire.nodes.values.filter(node => node.audio && node.isSink && !node.isStream)

  PwObjectTracker { objects: [root.sink, root.source] }

  component AudioLabel: Text {
    color: Theme.headingText
    font.family: @FONT@
    font.pixelSize: @FONT_SIZE@
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }
  component AudioButton: Button {
    id: button
    required property string glyph
    required property string label
    property bool selected: false
    implicitWidth: 38
    implicitHeight: 38
    Accessible.name: label
    ToolTip.visible: hovered
    ToolTip.text: label
    contentItem: Text {
      text: button.glyph
      font.family: @ICON_FONT@
      font.pixelSize: 23
      color: button.selected ? Theme.colors.base0D : Theme.detailText
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
      radius: 8
      color: button.hovered ? Theme.colors.base02 : Theme.colors.base01
      opacity: button.enabled ? 1 : 0.5
      border.width: 1
      border.color: button.selected || button.activeFocus ? Theme.colors.base0D : Qt.alpha(Theme.colors.base03, 0.45)
    }
  }

  RowLayout {
    Layout.fillWidth: true
    AudioButton {
      objectName: "speakerMute"
      enabled: root.sinkReady
      selected: root.sinkReady && root.sink.audio.muted
      glyph: selected ? "󰖁" : "󰕾"
      label: !enabled ? "No audio output" : selected ? "Unmute speakers" : "Mute speakers"
      onClicked: root.sink.audio.muted = !root.sink.audio.muted
    }
    Slider {
      id: volume
      objectName: "outputVolume"
      Layout.fillWidth: true
      implicitHeight: 38
      enabled: root.sinkReady
      from: 0
      to: 1
      stepSize: 0.01
      Accessible.name: "Output volume"
      // Native PipeWire volume uses the same perceptual scale as wpctl.
      onMoved: { if (root.sinkReady) root.sink.audio.volume = value; }
      Binding {
        target: volume
        property: "value"
        value: root.sinkReady ? root.sink.audio.volume : 0
        when: !volume.pressed
      }
      background: Rectangle {
        x: volume.leftPadding
        y: volume.topPadding + volume.availableHeight / 2 - height / 2
        implicitHeight: 6
        width: volume.availableWidth
        height: implicitHeight
        radius: 3
        color: Theme.colors.base02
        Rectangle {
          width: volume.visualPosition * parent.width
          height: parent.height
          radius: 3
          color: volume.enabled ? Theme.colors.base0D : Theme.colors.base03
        }
      }
      handle: Rectangle {
        x: volume.leftPadding + volume.visualPosition * (volume.availableWidth - width)
        y: volume.topPadding + volume.availableHeight / 2 - height / 2
        implicitWidth: 16
        implicitHeight: 16
        radius: 8
        color: volume.enabled ? Theme.colors.base0D : Theme.colors.base03
        border.width: volume.activeFocus ? 2 : 0
        border.color: Theme.headingText
      }
    }
    AudioLabel {
      Layout.preferredWidth: 44
      horizontalAlignment: Text.AlignRight
      text: root.sinkReady ? Math.round(root.sink.audio.volume * 100) + "%" : "--"
    }
    AudioButton {
      objectName: "microphoneMute"
      enabled: root.sourceReady
      selected: root.sourceReady && root.source.audio.muted
      glyph: selected ? "󰍭" : "󰍬"
      label: !enabled ? "No microphone" : selected ? "Unmute microphone" : "Mute microphone"
      onClicked: root.source.audio.muted = !root.source.audio.muted
    }
  }
  Button {
    id: chooser
    objectName: "outputChooser"
    Layout.fillWidth: true
    implicitHeight: 36
    padding: 8
    Accessible.name: "Choose audio output"
    onClicked: root.expanded = !root.expanded
    contentItem: RowLayout {
      AudioLabel {
        Layout.fillWidth: true
        text: root.sink ? root.sink.description || root.sink.name : "No audio output"
      }
      Text {
        text: root.expanded ? "󰅃" : "󰅀"
        font.family: @ICON_FONT@
        font.pixelSize: 20
        color: Theme.mutedText
      }
    }
    background: Rectangle {
      radius: 8
      color: chooser.hovered ? Theme.colors.base02 : Theme.colors.base01
      border.width: 1
      border.color: chooser.activeFocus ? Theme.colors.base0D : Qt.alpha(Theme.colors.base03, 0.45)
    }
  }
  ScrollView {
    visible: root.expanded && root.outputs.length > 0
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(root.outputs.length * 36, 144)
    contentWidth: availableWidth
    clip: true
    Column {
      width: parent.width
      Repeater {
        model: root.outputs
        Button {
          id: output
          required property var modelData
          objectName: "audioOutput-" + modelData.name
          width: parent.width
          height: 36
          padding: 8
          Accessible.name: modelData.description || modelData.name
          onClicked: { Pipewire.preferredDefaultAudioSink = modelData; root.expanded = false; }
          contentItem: AudioLabel {
            text: output.modelData.description || output.modelData.name
            color: output.modelData === root.sink ? Theme.colors.base0D : Theme.headingText
          }
          background: Rectangle {
            radius: 6
            color: output.hovered || output.modelData === root.sink ? Theme.colors.base02 : "transparent"
            border.color: output.activeFocus ? Theme.colors.base0D : "transparent"
          }
        }
      }
    }
  }
  Button {
    visible: root.expanded
    Layout.fillWidth: true
    implicitHeight: 30
    onClicked: root.advancedRequested()
    contentItem: AudioLabel { text: "More devices..."; color: Theme.mutedText }
    background: Rectangle { color: "transparent" }
  }
}
