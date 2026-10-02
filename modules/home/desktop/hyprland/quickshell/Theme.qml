pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string mode: @DYNAMIC@ ? (selection.text().trim() || @DEFAULT_MODE@) : @DEFAULT_MODE@
  readonly property var colors: JSON.parse(palette.text())
  // Latte accent slots are too pale for text on its light cards.
  readonly property string headingText: mode === "light" ? colors.base05 : colors.base07
  readonly property string detailText: mode === "light" ? colors.base05 : colors.base06
  readonly property string mutedText: mode === "light" ? colors.base05 : colors.base04
  readonly property string selectedText: mode === "light" ? "#ffffff" : colors.base00

  // Reloading a FileView also rebuilds its watcher. Keep this watcher alive
  // while the separate reader reloads, so rapid renames cannot fall in a gap.
  FileView {
    path: @MODE_PATH@
    preload: false
    watchChanges: @DYNAMIC@
    onFileChanged: selection.reload()
  }

  FileView {
    id: selection
    path: @MODE_PATH@
    // The selection is one word. Avoid an older in-flight async read winning.
    preload: false
    blockAllReads: true
  }

  FileView {
    id: palette
    path: @PALETTE_PATH@
    blockLoading: true
  }
}
