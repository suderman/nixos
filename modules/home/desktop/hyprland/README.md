# Hyprland

This is my trusty desktop of choice! 💻

## Keyboard Bindings

These are largely assigned within
[Hyprland](https://wiki.hypr.land/Configuring/Binds) but with a few handled by
[keyd](https://github.com/rvaiya/keyd). I prefer an Apple-style keyboard layout
with the `Super` key directly next to `Space`. My
[HHKB](https://happyhackingkb.com) keyboard supports this layout and keyd can
remap it on other keyboards.

### Launchers

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

### Workspaces

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
| `Super` `M`            |                       | Toggle window marks (hold to clear all)   |
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
| `Esc`                  |                       | Hold to toggle titlebars                  |

### Groups

| Key                | Alt Key                    | Function                       |
| ------------------ | -------------------------- | ------------------------------ |
| `Super` `/`        | `Super` `Alt` `mouse_left` | Toggle window group or lock    |
| `Super` `<>`       |                            | Navigate window group tabs     |
| `Super` `Alt` `<>` |                            | Reorder windows inside a group |
| `Super` `Q`        |                            | Disperse windows out of group  |

### Media

| Key                      | Alt Key               | Function                            |
| ------------------------ | --------------------- | ----------------------------------- |
| `VolumeDown`             | `Tab` `A`             | Lower volume                        |
| `VolumeUp`               | `Tab` `S`             | Raise volume                        |
| `Mute`                   | `Tab` `D`             | Mute volume                         |
| `MicMute`                | `Tab` `C`             | Mute microphone                     |
| `Media`                  | `Tab` `V`             | Audio device chooser                |
| `Shift` `Media`          | `Tab` `Shift` `V`     | Bluetooth device chooser            |
| `PlayPause`              | `Tab` `Space`         | Play or pause active player         |
| `Alt` `PlayPause`        | `Tab` `Alt` `Space`   | Play or pause all players           |
| `Shift` `PlayPause`      | `Tab` `Shift` `Space` | Change active player                |
| `PreviousSong`           | `Tab` `R`             | Rewind _(hold for previous song)_   |
| `NextSong`               | `Tab` `F`             | Fast forward _(hold for next song)_ |
| `BrightnessDown`         | `Tab` `Z`             | Lower brightness                    |
| `BrightnessUp`           | `Tab` `X`             | Raise brightness                    |
| `Shift` `BrightnessDown` | `Tab` `Shift` `Z`     | Start blue light filter             |
| `Shift` `BrightnessUp`   | `Tab` `Shift` `X`     | Stop blue light filter              |

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
| `Home`           | `Tab` `,`   | Cursor start of line  |
| `End`            | `Tab` `.`   | Cursor end of line    |
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

```conf
# ---
windowrule=tile,class:(zwiftapp.exe)
--> windowrule = tile on, match:class (zwiftapp.exe)
# ---
windowrule=tag +media, class:(org.pwmt.zathura)
--> windowrule = tag +media, match:class (org.pwmt.zathura)
# ---
windowrule=float, class:^(org.telegram.desktop|telegramdesktop)$, title:^(Media viewer)$
--> windowrule = float on, match:class ^(org.telegram.desktop|telegramdesktop)$, match:title ^(Media viewer)$
# ---
windowrule=tag +game, class:[Ss]team
--> windowrule = tag +game, match:class [Ss]team
# ---
windowrule=tag +game, class:^steam_app_(.*)$
--> windowrule = tag +game, match:class ^steam_app_(.*)$
# ---
windowrule=tag +game, class:^(.*).bin.x86$
--> windowrule = tag +game, match:class ^(.*).bin.x86$
# ---
windowrule=tag +game, class:^(.*)x86_64$
--> windowrule = tag +game, match:class ^(.*)x86_64$
# ---
windowrule=noblur,class:^Sparrow$,title:^()$
--> windowrule = no_blur on, match:class ^Sparrow$, match:title ^()$
# ---
windowrule=tag +pwd, class:(1Password), title:^(1Password)$
--> windowrule = tag +pwd, match:class (1Password), match:title ^(1Password)$
# ---
windowrule=float, tag:pwd
windowrule=size 1024 768, tag:pwd
--> windowrule = float on, size 1024 768, match:tag pwd
# ---
windowrule=tag +pwd_dialog, class:(1Password), title:^(.*)Password — 1Password$
--> windowrule = tag +pwd_dialog, match:class (1Password), match:title ^(.*)Password — 1Password$
# ---
windowrule=float, tag:pwd_dialog
windowrule=size 1280 240, tag:pwd_dialog
windowrule=center, tag:pwd_dialog
windowrule=pin, tag:pwd_dialog
--> windowrule = float on, size 1280 240, center on, pin on, match:tag pwd_dialog
# ---
windowrule=float, class:chrome-__tmp_mutt.html-Default
windowrule=size 800 900, class:chrome-__tmp_mutt.html-Default
windowrule=animation gnomed, class:chrome-__tmp_mutt.html-Default
--> windowrule = float on, size 800 900, animation gnomed, match:class chrome-__tmp_mutt.html-Default
# ---
windowrule=tag +media, class:(mpv)
--> windowrule = tag +media, match:class (mpv)
# ---
windowrule=tag +media, class:(imv)
--> windowrule = tag +media, match:class (imv)
# ---
windowrule=tag +dialog, class:(file-png|file-jpeg)
--> windowrule = tag +dialog, match:class (file-png|file-jpeg)
# ---
windowrule=tag +dialog, class:gimp, title:(Open.*|Export.*|Save.*|Preferences.*|Configure.*|Module.*)
--> windowrule = tag +dialog, match:class gimp, match:title (Open.*|Export.*|Save.*|Preferences.*|Configure.*|Module.*)

# ---
windowrule=tag +yt, class:[Ff]reetube
--> windowrule = tag +yt, match:class [Ff]reetube
# ---
windowrule=tag +web, class:(firefox)
--> windowrule = tag +web, match:class (firefox)
# ---
windowrule=tag +pip, title:^(Picture-in-Picture)$
--> windowrule = tag +pip, match:title ^(Picture in picture)$
# ---
windowrule=tag +web, class:(chromium-browser)
--> windowrule = tag +web, match:class (chromium-browser)
# ---
windowrule=tag +pip, title:^(Picture in picture)$
--> windowrule = tag +pip, match:title ^(Picture-in-Picture)$
# ---
windowrule=move 45.8% 30,class:gsimplecal
windowrule=opacity 0.8,class:gsimplecal
# ---
windowrule=workspace 9, tag:game
windowrule=fullscreen, tag:game
--> windowrule = workspace 9, fullscreen on, match:tag game
# ---
windowrule=idleinhibit fullscreen, class:.*
--> windowrule = idle_inhibit fullscreen, match:class .*
# ---
windowrule=bordersize 1, tag:mark
--> windowrule = border_size 1, match:tag mark
# ---
windowrule=bordersize 2, pinned:1
--> windowrule = border_size 2, match:pin 1
# ---
windowrule=decorate 0, pinned:1, focus:0
--> windowrule = decorate 0, match:pin 1, match:focus 0
# ---
windowrule=float, tag:pip
windowrule=pin, tag:pip
windowrule=keepaspectratio, tag:pip
windowrule=size 480 270, tag:pip
windowrule=minsize 240 135, tag:pip
windowrule=maxsize 960 540, tag:pip
windowrule=move 100%-490 100%-280, tag:pip
--> windowrule = float on, pin on, keep_aspect_ratio on, size 480 270, min_size 240 135, max_size 960 540, move ((monitor_w*1)-490) ((monitor_h*1)-280), match:tag pip
# ---
windowrule=float, tag:dialog
windowrule=center, tag:dialog
windowrule=noborder, tag:dialog
windowrule=size 1280 768, tag:dialog
--> windowrule = float on, center on, border_size 0, size 1280 768, match:tag dialog
# ---
windowrule=tag +dialog, title:(Progress|Save File|Save As)
--> windowrule = tag +dialog, match:title (Progress|Save File|Save As)
# ---
windowrule=tag +dialog, class:(xdg-desktop-portal-gtk)
--> windowrule = tag +dialog, match:class (xdg-desktop-portal-gtk)
# ---
windowrule=tag +dialog, class:(re.sonny.Junction)
--> windowrule = tag +dialog, match:class (re.sonny.Junction)
# ---
windowrule=float, tag:media
windowrule=size 1280 720, tag:media
--> windowrule = float on, size 1280 720, match:tag media
# ---
windowrule=fullscreen, class:com.gabm.satty
windowrule=float, class:com.gabm.satty
--> windowrule = fullscreen on, float on, match:class com.gabm.satty
# ----------
```
