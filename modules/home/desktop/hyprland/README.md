# Hyprland

This is my trusty desktop of choice! 💻

## Configuration ownership

Home Manager owns `hyprland.lua` through its native `configType = "lua"`
module. It also owns the systemd startup hook. Do not add a second session
bootstrap or a legacy `hyprland.conf`.

- `lua.nix` renders host data and the sorted feature list with
  `lib.generators.toLua`.
- `lua/conf/`, `lua/binds/`, and `lua/rules/` hold shared compositor policy.
- App and service modules contribute `wayland.windowManager.hyprland.lua.features`.
  Keep their binds, rules, and event listeners beside the owning service.
- `~/.config/hypr/local/init.lua` is the writable scratch hook. It may be absent.
  Generated modules are required; broken modules and scratch code must report
  errors rather than silently disappear.

Hyprland clears Lua modules, bindings, and listeners on reload. Do not keep a
second cache of compositor state. Workspace-rule changes settle on the next
compositor turn, so tests must read them in a later IPC request.

The Lua keyd mapper owns both window and layer mappings in Hyprland sessions.
Keep the stock application-mapper service disabled there. It sends its own
`keyd bind reset` commands and would overwrite the layer mappings.

Use `lib.util.active_workspace()` for the visible workspace. Special workspaces
are overlays and are not returned by `hl.get_active_workspace()`. Shell callers
use `hypr-activeworkspace`, which adds a canonical `selector` to the workspace
JSON. Main replaces Lua `config_name` with `addressable_name` and no longer gives
named workspaces numeric IDs. Keep that version distinction in these helpers,
not in each widget or bind.

Declare plugins with `hl.plugin.load`. Hyprland reloads after loading them and
registers their functions under `hl.plugin.<name>`. Configure Hyprbars when
`hl.plugin.hyprbars` exists. A sleep cannot prove that a plugin is ready.
Plugins must be built against the same Hyprland revision as the compositor.

## Appearance and daily tools

See [desktop appearance](../default/options/desktop-theme/README.md) for the
prepared light/dark palettes, supported apps, and reload limits.

- Super+Alt+Shift+T toggles appearance without a system activation.
- Super+F1 searches live Hyprland and configured keyd shortcuts.
- Super+Alt+Shift+U silences or resumes notifications; Waybar shows the mode.
- Super+Print reads English screen text. Super+Shift+Print reads QR data into
  the private clipboard without adding it to the configured Cliphist history.
- Blezz retains the existing launcher and adds Appearance and Share entries.

On Quickshell hosts, Super+backtick or Waybar's settings button opens quick settings
on the focused monitor. The panel follows the current palette. Light/dark,
notification silence, and night light keep it open. Theme choices sit in one row without an outer box; notification and night-light states appear beside their
labels. Failed controls get a red border and an error tooltip, not footer text.
Waybar keeps power at the far right, with settings beside it. The cog uses the
accent color while the panel is open, including when opened by keyboard.
A brightness slider appears when a backlight device is available. It sets
1-100% through `mediactl brightness set`, reusing `lightctl` and its OSD.
Brightness keys keep their existing step behavior. While open, the panel reads
the backlight every 500 ms to follow keys and external changes; reads stop when
closed. Missing backlights hide the slider. Kit keeps its gamma controls.
Audio stays inline. The speaker and microphone buttons toggle their default
devices' mute state. The output slider sets 0-100%; an external boost above 100%
is displayed without changing it. The current output row expands a scrollable
list of connected outputs. Selection changes PipeWire's preferred default;
WirePlumber handles stream routing. "More devices..." closes the panel and opens
the existing Rofi picker, including its saved Bluetooth connection choices.
Media keys and external changes update the panel through native PipeWire events.
Missing devices disable their controls. Bluetooth also stays inline. Its power
button controls the default adapter; blocked or missing adapters disable it.
The Bluetooth row expands a scrollable list of paired devices. Clicking a device
connects or disconnects it, with pending and failed-connection feedback. External
BlueZ changes update the panel without polling. It does not scan, pair, unblock,
or forget devices. "More Bluetooth settings..." closes the panel and opens
Bluetuith. Audio and Bluetooth drawers close each other to keep the panel short.
Screenshot, Record Screen, OCR Text, QR Scan, and Color Picker use the existing
`printscreen` actions. Each closes the panel, then waits 250 ms before launching
so the panel stays out of the capture. Screenshot opens Satty for cropping and
annotation; Record Screen toggles recording. OCR reads English text; QR Scan
uses the private clipboard without adding decoded data to Cliphist. Existing
Print-key shortcuts remain unchanged. LocalSend also closes the panel.
Lock and Suspend close the panel and use the configured locker and systemd.
Power opens logout, reboot, and shutdown choices. Each needs a second
confirmation; Cancel gets keyboard focus. Escape, closing, and pointer-leave
clear the choice. Lock/logout/reboot/shutdown commands come from the existing
wlogout layout. Waybar power and XF86PowerOff still open that menu.
Hypridle locks before sleep and delays suspend until the compositor confirms
locking. Idle timeouts and Cog's lid policy stay unchanged.
Escape, the close button, or a click outside dismisses it. Leaving the panel
dismisses it after 300 ms, like the quota popups. Returning before that delay
cancels dismissal.

Pinned Quickshell 0.3.0 can stall when the PipeWire server stops. Device removal
and reappearance work, but after restarting PipeWire, restart Quickshell too
with `systemctl --user restart quickshell`. No watchdog or second audio state
owner is added.

Waybar's coffee cup remains the only presentation-mode control. It blocks
automatic idle actions, including locking and screen-off. It does not block
manual lock or suspend. The panel does not create another idle inhibitor.

## Checks and release testing

From the repository root, after adding new source files to the Git index:

```sh
nix develop --command nix build '.#checks.x86_64-linux.hyprland' -L
```

Git flakes omit untracked files. Do not work around that with raw `path:.` in
this checkout: it includes ignored Sim disks and private keys. For unstaged
experiments, build from a snapshot containing only tracked and non-ignored files.

This runs Lua state tests, workspace JSON tests, and syntax checks. It renders
Kit, Pow, Cog, and Sim configurations and verifies each with pinned Hyprland.
The output contains each host's Lua files, Waybar JSON, and packaged helper
scripts. Offline verification does not load plugins or prove that a desktop starts.

Run candidate releases in Sim before changing the production lock. Use disposable
QCOW2 overlays when testing an installed Sim disk. Stop Syncthing, Tailscale, and
other services that could sync or publish the cloned machine's state. Do not run
the identity-generation wrappers for compositor experiments.

Copy the rendered check closure into Sim with `nix copy`, then copy its `sim/`
directory into a writable guest directory. Start Hyprland as Jon in a real
logind session. For serial-only QEMU, use a systemd transient service with
`PAMName=login`, `TTYPath=/dev/tty1`, and `StandardInput=tty`. Set
`HOME=/home/jon`, `XDG_RUNTIME_DIR=/run/user/1000`, and
`LIBGL_ALWAYS_SOFTWARE=1` for the software-rendered test. Stop the guest display
manager first so it does not compete for the seat. Stop or mask guest Hypridle
for the test session so an unattended run does not lock halfway through.
When using the exported `bin/` directory, prepend it to `PATH` in the launcher
script after PAM setup. The login environment can override a transient service's
`PATH` setting.

Use an explicit wrapper that forwards every argument to `hyprctl -i 0` inside
Sim as Jon. Never point this test at the physical desktop:

```sh
python3 modules/home/desktop/hyprland/test-runtime.py /path/to/sim-hyprctl
```

The test checks numbered, named, and visible special workspaces, floating-window
hide/restore, fullscreen modes, groups, and repeated reloads. It invokes the real
layout-bind callbacks. Add `--qemu-monitor /path/to/monitor.sock` before the
wrapper argument to test Super+Slash and Super+Alt+Slash through QEMU keyboard
events, including after reload. This still does not test a physical keyboard or
touchpad. If Hyprbars is loaded, it checks that feature settings survive reloads.
Test candidate Hyprland both without plugins and with matching official plugins.
Check `hyprctl configerrors` and the guest journal after each run. Inject a broken
feature once to confirm that configuration errors remain visible.

The Quickshell check validates quick-settings action wiring on Kit and Cog and
absence on Pow and Sim. For native rendering and focus tests, copy its closure
into a disposable Sim session and run:

```sh
python3 modules/home/desktop/hyprland/quickshell/test-settings-runtime.py \
  /nix/store/<quickshell-check>/kit/config \
  /nix/store/<quickshell-package> /path/to/qemu-monitor.sock /path/to/sim-user-wrapper
```

The wrapper must run each command as the desktop user inside Sim with its
Wayland and Hyprland environment. The test checks live theme, notification, and
night-light actions, failed-command feedback, detached launches using mock
commands, monitor selection, session-lock protection, and Escape/outside-click
dismissal. Native session tests substitute all five session commands before
clicking them. They verify direct lock/suspend handoff, cancellation, confirmation,
and clearing pending choices without ending or sleeping the test session.
Device pickers and capture commands still need user acceptance on
real hardware. Set `QUICK_SETTINGS_GRIM` to the guest's absolute Grim path to
also click all five capture buttons. That test substitutes only the `printscreen`
command inside Sim and takes compositor screenshots at handoff, checking that
the panel is absent. It does not start recording or change the clipboard.
Set `QUICK_SETTINGS_WAYBAR` to the check output's
`kit/waybar.json` and `QUICK_SETTINGS_GRIM` to the guest's absolute Grim path to
add native cog/bell clicks, cog tint/reset, pointer-leave dismissal/cancel, and
screenshot-based bell state checks. This test
uses an isolated three-module Waybar with a one-hour status interval to prove
signal refresh rather than polling. Its pointer coordinates require the
1280x800 Sim display.

To verify the compiled Hypridle configuration and real locker in Sim:

```sh
python3 modules/home/desktop/hyprland/quickshell/test-session-lock.py \
  /nix/store/<quickshell-check> /path/to/sim-user-wrapper
```

This verifies lock-notify inhibition and a real logind lock request, then unlocks
only the disposable guest. It does not suspend. Actual suspend/resume and power
operations still need user acceptance on the target host.

For inline audio, use the same disposable Sim wrapper:

```sh
python3 modules/home/desktop/hyprland/quickshell/test-audio-runtime.py \
  /nix/store/<quickshell-check>/kit/config \
  /nix/store/<quickshell-package> /path/to/sim-user-wrapper
```

This creates virtual speakers, headphones, and a microphone. It exercises native
slider/mute clicks, media-key sync, external boost, output switching with an
active stream, and device removal/reappearance. It never plays sound on physical
hosts. PipeWire server restart is a separate upstream limitation, not covered by
the passing device-loss check.

For laptop brightness, use the same disposable Sim wrapper:

```sh
python3 modules/home/desktop/hyprland/quickshell/test-brightness-runtime.py \
  /nix/store/<quickshell-check> \
  /nix/store/<quickshell-package> /path/to/sim-user-wrapper
```

This substitutes only backlight hardware responses. Native slider clicks, drags,
keyboard input, compiled media commands, and the Quickshell OSD remain real.
It checks range limits, rapid writes, external changes, missing devices, failed
writes, and polling only while open. Real backlight response and permissions
still need acceptance on Cog.

For Bluetooth, use the test-only Python environment exported by the check:

```sh
python3 modules/home/desktop/hyprland/quickshell/test-bluetooth-runtime.py \
  /nix/store/<quickshell-check>/kit/config \
  /nix/store/<quickshell-package> /nix/store/<quickshell-check>/test-python \
  /path/to/sim-user-wrapper
```

The test runs a private BlueZ D-Bus fixture, never the physical system bus. It
checks native power/connect/disconnect clicks, pending states, failure/retry,
external changes, paired-only filtering, adapter removal/reappearance, themes,
drawer lifecycle, and the Bluetuith handoff with a mock launch. Real radio
connections still need hardware acceptance. The pinned adapter API reports power
through BlueZ state but exposes write errors only in Quickshell logs.

Keep physical GPU, touchpad, multi-monitor scaling, and disabled dynamic-cursor
plugin checks separate. Passing Sim proves the tested revision, not compatibility
with an unreleased revision.

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

| Key                   | Key                    | Function                           |
| --------------------- | ---------------------- | ---------------------------------- |
| `Super` `← →`         | `Super` `mouse_scroll` | Navigate workspaces                |
| `Super` `Alt` `N`     |                        | Cycle next workspace               |
| `Super` `Alt` `P`     |                        | Cycle previous workspace           |
| `Super` `1-9`         |                        | Jump to workspace                  |
| `Super` `Esc`         |                        | Toggle special workspace           |
| `Super` `Shift` `Esc` |                        | Send window to special workspace   |
| `Super` `N`           |                        | Cycle next window in workspace     |
| `Super` `P`           |                        | Cycle previous window in workspace |
| `Super` `/`           |                        | Cycle next layout in workspace     |
| `Super` `Alt` `/`     |                        | Cycle previous layout in workspace |

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
| `Super` `Alt` `O`      |                       | Toggle visibility of floating windows     |
| `Super` `Shift` `O`    |                       | Focus floating windows                    |
| `Esc`                  |                       | Hold to toggle titlebars                  |

### Groups

| Key                | Alt Key                    | Function                                    |
| ------------------ | -------------------------- | ------------------------------------------- |
| `Super` `<>`       | `Super` `Alt` `mouse_left` | Navigate window group tabs (hold to toggle) |
| `Super` `Alt` `<>` |                            | Reorder windows inside a group              |
| `Super` `Q`        |                            | Disperse windows out of group               |

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

| Key                       | Alt Key     | Function                        |
| ------------------------- | ----------- | ------------------------------- |
| `Esc`                     |             | Dismiss notification            |
| `Super` `Alt` `U`         |             | Undo dismissal of notifications |
| `Super` `Shift` `Alt` `P` |             | Random wallpaper                |
| `Super` `Alt`             |             | Sleep display                   |
| `NumLock`                 |             | Sleep display                   |
| `Power`                   |             | Show poweroff menu              |
| `Ctrl` `Alt` `F1-F9`      | `Tab` `1-9` | Jump to TTY                     |
