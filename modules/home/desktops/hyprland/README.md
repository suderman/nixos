# Hyprland

This is my trusty desktop of choice.

## Keyboard Bindings

These are largely assigned within
[Hyprland](https://wiki.hypr.land/Configuring/Binds) but with a few handled by
[keyd](https://github.com/rvaiya/keyd).

## Launchers

| Key               | Function                            |
| ----------------- | ----------------------------------- |
| `Super`           | Launcher and window switcher        |
| `Super` `Return`  | Launch terminal (hold to float)     |
| `Super` `B`       | Launch browser (hold to float)      |
| `Super` `Alt` `B` | Launch alt browser (hold to float)  |
| `Super` `E`       | Launch editor (hold to float)       |
| `Super` `Alt` `E` | Launch alt editor (hold to float)   |
| `Super` `Y`       | Launch file manager (hold to float) |
| `Super` `Alt` `Y` | Launch alt editor (hold to float)   |

## Workspaces

| Key                 | Key                    | Function                                      |
| ------------------- | ---------------------- | --------------------------------------------- |
| `Super` `← →`       | `Super` `mouse_scroll` | Navigate workspaces                           |
| `Super` `1-9`       |                        | Jump to workspace                             |
| `Super` `Esc`       |                        | Toggle special workspace                      |
| `Super+Shift` `Esc` |                        | Send window to special workspace              |
| `Super` `M`         |                        | Minimize/maximize window in special workspace |

### Windows

| Key                    | Alt Key               | Function                            |
| ---------------------- | --------------------- | ----------------------------------- |
| `Super` `Tab`          |                       | Navigate window history             |
| `Super` `HJKL`         |                       | Focus window                        |
| `Super` `Alt` `HJKL`   | `Super` `mouse_left`  | Move window within workspace        |
| `Super` `Shift` `HJKL` | `Super` `mouse_right` | Resize window                       |
| `Super` `Shift` `1-9`  |                       | Resize floating window % and centre |
| `Super` `Alt` `1-9`    |                       | Move window to new workspace        |
| `Super` `Q`            |                       | Kill window                         |
| `Super` `F`            |                       | Fullscreen (hold for max)           |
| `Super` `U`            |                       | Focus urgent window                 |
| `Super` `I`            |                       | Tile window or toggle split         |
| `Super` `Alt` `I`      |                       | Tile window or swap split           |
| `Super` `Shift` `I`    |                       | Focus tiled windows                 |
| `Super` `O`            |                       | Float window or pin window          |
| `Super` `Alt` `O`      |                       | Float window or cycle position      |
| `Super` `Shift` `O`    |                       | Focus floating windows              |
| `Esc`                  |                       | Hold to toggle titlebars            |

### Groups

| Key                | Alt Key                    | Function                       |
| ------------------ | -------------------------- | ------------------------------ |
| `Super` `/`        | `Super` `Alt` `mouse_left` | Toggle window group or lock    |
| `Super` `<>`       |                            | Navigate window group tabs     |
| `Super` `Alt` `<>` |                            | Reorder windows inside a group |
| `Super` `Q`        |                            | Disperse windows out of group  |

### Media

| Key                 | Alt Key               | Function                          |
| ------------------- | --------------------- | --------------------------------- |
| `VolumeDown`        | `Tab` `A`             | Lower volume                      |
| `VolumeUp`          | `Tab` `S`             | Raise volume                      |
| `Mute`              | `Tab` `D`             | Mute volume                       |
| `Media`             | `Tab` `M`             | Audio device chooser              |
| `Shift` `Media`     | `Tab` `Shift` `M`     | Bluetooth device chooser          |
| `PlayPause`         | `Tab` `Space`         | Play or pause active player       |
| `Alt` `PlayPause`   | `Tab` `Alt` `Space`   | Play or pause all players         |
| `Shift` `PlayPause` | `Tab` `Shift` `Space` | Change active player              |
| `PreviousSong`      | `Tab` `R`             | Rewind (hold for previous song)   |
| `NextSong`          | `Tab` `F`             | Fast forward (hold for next song) |

### Screenshots

| Key             | Alt Key           | Function                                          |
| --------------- | ----------------- | ------------------------------------------------- |
| `Print`         | `Tab` `I`         | Screen to clipboard (hold for interactive region) |
| `Shift` `Print` | `Tab` `Shift` `I` | Screen to file (hold for interactive screen)      |
| `Alt` `Print`   | `Tab` `Alt` `I`   | Color picker                                      |

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
| `Alt` `A`    | Volume Down      |
| `Alt` `S`    | Volume Up        |
| `Alt` `D`    | Mute             |

### Text Editing

| Key         | Alt Key          | Function                |
| ----------- | ---------------- | ----------------------- |
| `Super` `X` | `Shift` `Delete` | Cut                     |
| `Super` `C` | `Ctrl` `Insert`  | Copy                    |
| `Super` `V` | `Shift` `Insert` | Paste                   |
| `←`         | `Tab` `H`        | Cursor left             |
| `↓`         | `Tab` `J`        | Cursor down             |
| `↑`         | `Tab` `K`        | Cursor up               |
| `→`         | `Tab` `L`        | Cursor right            |
| `Ctrl` `→`  | `Tab` `W`        | Cursor to next word     |
| `Ctrl` `←`  | `Tab` `B`        | Cursor to previous word |
| `Home`      | `Tab` `Q`        | Cursor start of line    |
| `End`       | `Tab` `E`        | Cursor end of line      |
| `PageUp`    | `Tab` `P`        | Cursor up one page      |
| `PageDown`  | `Tab` `N`        | Cursor down one page    |

### Other

| Key                 | Alt Key              | Function                        |
| ------------------- | -------------------- | ------------------------------- |
| `Esc`               |                      | Dismiss notification            |
| `Super` `Alt` `U`   |                      | Undo dismissal of notifications |
| `Super` `Shift` `Q` |                      | Quit Hyprland                   |
| `NumLock`           |                      | Sleep display                   |
| `Power`             |                      | Show poweroff menu              |
| `Tab` `1-9`         | `Ctrl` `Alt` `F1-F9` | Jump to TTY                     |
