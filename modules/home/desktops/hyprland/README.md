# Hyprland

This is my trusty desktop of choice! 💻

## Keyboard Bindings

These are largely assigned within
[Hyprland](https://wiki.hypr.land/Configuring/Binds) but with a few handled by
[keyd](https://github.com/rvaiya/keyd). I prefer an Apple-style keyboard layout
with the `Super` key directly next to `Space`. My
[HHKB](https://happyhackingkb.com) keyboard supports this layout and keyd can
remap it on other keyboards.

## Launchers

| Key               | Function                                  |
| ----------------- | ----------------------------------------- |
| `Super`           | Launcher and window switcher              |
| `Super` `Return`  | Launch terminal _(hold to float)_         |
| `Super` `B`       | Launch web browser _(hold to float)_      |
| `Super` `Alt` `B` | Launch alt web browser _(hold to float)_  |
| `Super` `E`       | Launch text editor _(hold to float)_      |
| `Super` `Alt` `E` | Launch alt text editor _(hold to float)_  |
| `Super` `Y`       | Launch file manager _(hold to float)_     |
| `Super` `Alt` `Y` | Launch alt file manager _(hold to float)_ |

## Workspaces

| Key                   | Key                    | Function                                            |
| --------------------- | ---------------------- | --------------------------------------------------- |
| `Super` `← →`         | `Super` `mouse_scroll` | Navigate workspaces                                 |
| `Super` `1-9`         |                        | Jump to workspace                                   |
| `Super` `Esc`         |                        | Toggle special workspace                            |
| `Super` `Shift` `Esc` |                        | Send window to special workspace                    |
| `Super` `P`           |                        | Toggle visibility of floating windows per workspace |

### Windows

| Key                    | Alt Key               | Function                                  |
| ---------------------- | --------------------- | ----------------------------------------- |
| `Super` `Tab`          |                       | Navigate window history (or window marks) |
| `Super` `HJKL`         |                       | Focus window                              |
| `Super` `Alt` `HJKL`   | `Super` `mouse_left`  | Move window within workspace              |
| `Super` `Shift` `HJKL` | `Super` `mouse_right` | Resize window                             |
| `Super` `Shift` `1-9`  |                       | Resize floating window % and centre       |
| `Super` `Alt` `1-9`    |                       | Move window to new workspace              |
| `Super` `Q`            |                       | Kill window                               |
| `Super` `F`            |                       | Fullscreen _(hold for max)_               |
| `Super` `U`            |                       | Focus urgent window                       |
| `Super` `I`            |                       | Tile window or toggle split               |
| `Super` `Alt` `I`      |                       | Tile window or swap split                 |
| `Super` `Shift` `I`    |                       | Focus tiled windows                       |
| `Super` `O`            |                       | Float window or pin window                |
| `Super` `Alt` `O`      |                       | Float window or cycle position            |
| `Super` `Shift` `O`    |                       | Focus floating windows                    |
| `Super` `M`            |                       | Toggle window marks (hold to clear all)   |
| `Esc`                  |                       | Hold to toggle titlebars                  |

### Groups

| Key                | Alt Key                    | Function                       |
| ------------------ | -------------------------- | ------------------------------ |
| `Super` `/`        | `Super` `Alt` `mouse_left` | Toggle window group or lock    |
| `Super` `<>`       |                            | Navigate window group tabs     |
| `Super` `Alt` `<>` |                            | Reorder windows inside a group |
| `Super` `Q`        |                            | Disperse windows out of group  |

### Media

| Key                 | Alt Key               | Function                            |
| ------------------- | --------------------- | ----------------------------------- |
| `VolumeDown`        | `Tab` `A`             | Lower volume                        |
| `VolumeUp`          | `Tab` `S`             | Raise volume                        |
| `Mute`              | `Tab` `D`             | Mute volume                         |
| `Media`             | `Tab` `M`             | Audio device chooser                |
| `Shift` `Media`     | `Tab` `Shift` `M`     | Bluetooth device chooser            |
| `PlayPause`         | `Tab` `Space`         | Play or pause active player         |
| `Alt` `PlayPause`   | `Tab` `Alt` `Space`   | Play or pause all players           |
| `Shift` `PlayPause` | `Tab` `Shift` `Space` | Change active player                |
| `PreviousSong`      | `Tab` `R`             | Rewind _(hold for previous song)_   |
| `NextSong`          | `Tab` `F`             | Fast forward _(hold for next song)_ |

### Screenshots

| Key             | Alt Key           | Function                                              |
| --------------- | ----------------- | ----------------------------------------------------- |
| `Print`         | `Tab` `I`         | Capture image from screen                             |
| `Alt` `Print`   | `Tab` `Alt` `I`   | Capture video from screen (press again to toggle off) |
| `Shift` `Print` | `Tab` `Shift` `I` | Color picker                                          |

### Applications (where available)

| Key          | Function         |
| ------------ | ---------------- |
| `Super` `W`  | Close tab        |
| `Super` `R`  | Reload or rename |
| `Super` `T`  | New tab          |
| `Super` `N`  | New window       |
| `Super` `[]` | Navigate tabs    |
| `Super` `A`  | Select all       |
| `Super` `Z`  | Undo             |
| `J+K`        | Escape           |

### Text Editing

| Key              | Alt Key     | Function              |
| ---------------- | ----------- | --------------------- |
| `Shift` `Delete` | `Super` `X` | Cut                   |
| `Ctrl` `Insert`  | `Super` `C` | Copy                  |
| `Shift` `Insert` | `Super` `V` | Paste                 |
| `←`              | `Tab` `H`   | Cursor left           |
| `↓`              | `Tab` `J`   | Cursor down           |
| `↑`              | `Tab` `K`   | Cursor up             |
| `→`              | `Tab` `L`   | Cursor right          |
| `Ctrl` `←`       | `Tab` `B`   | Cursor back a word    |
| `Ctrl` `→`       | `Tab` `W`   | Cursor forward a word |
| `Home`           | `Tab` `Q`   | Cursor start of line  |
| `End`            | `Tab` `E`   | Cursor end of line    |
| `PageUp`         | `Tab` `P`   | Cursor up one page    |
| `PageDown`       | `Tab` `N`   | Cursor down one page  |

### Other

| Key                  | Alt Key     | Function                        |
| -------------------- | ----------- | ------------------------------- |
| `Esc`                |             | Dismiss notification            |
| `Super` `Alt` `U`    |             | Undo dismissal of notifications |
| `Super` `Shift` `Q`  |             | Quit Hyprland                   |
| `NumLock`            |             | Sleep display                   |
| `Power`              |             | Show poweroff menu              |
| `Ctrl` `Alt` `F1-F9` | `Tab` `1-9` | Jump to TTY                     |
