# Desktop appearance

`desktop-theme light`, `desktop-theme dark`, or `desktop-theme toggle` selects
prepared Stylix palettes in the current user session. Super+Alt+Shift+T invokes
the same toggle. The Blezz menu exposes both choices under Appearance.

Both palettes are built with Home Manager. Switching does not run Nix, sudo,
`switch-to-configuration`, or a compositor restart. The old light system
specialisation and root theme command are removed. System consoles and services
retain their declarative theme.

## Ownership

- `programs.stylix-theme-toggle.darkScheme` and `lightScheme` remain the shared
  palette pair used by this module and the Emacs style export. That option name
  no longer means a root activation command.
- Stylix still owns fonts, sizes, cursor policy, and palette overrides.
- Home Manager builds both sets of assets, named GTK3 themes, and paired
  Qt5ct/Qt6ct palettes and Kvantum themes. Qt fonts, dialogs, and packages remain
  under the existing Stylix/Home Manager configuration.
- `~/.local/state/desktop-theme/mode` stores the user's selection. `current`
  points to that mode's immutable assets. This directory is persisted separately
  from editable configuration copies in `~/.local/store`.
- Activation prepares the selected assets before linking app configs. A running
  session reapplies its choice after Stylix activation; a new session applies it
  through `desktop-theme.service`.
- `lua/lib/appearance.lua` owns Hyprland colors. Local Lua can still override
  them, but the next appearance switch reapplies the shared palette.

The command validates assets before changing the selection and serializes
concurrent requests. A failed app refresh reports an error while retaining the
requested mode. `desktop-theme apply` retries those refreshes. `get` prints the
selection without changing anything. `prepare` is the activation-only step.

## Supported consumers

| Consumer              | Behavior                                                                                                                                                                                                  |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Hyprland and Hyprbars | Live borders, groups, background, shadow, and titlebar colors. Geometry and plugin settings stay intact.                                                                                                  |
| Waybar                | Reloads styles and config with USR2. No compositor restart.                                                                                                                                               |
| Rofi and Blezz        | Read the current palette when opened. Existing popups must be reopened.                                                                                                                                   |
| Quickshell popups     | Existing Herdr, MiniMax, and codex-lb popups update while open and pinned. No shell restart or data reset.                                                                                                |
| Mako                  | Reloads palette colors without changing notification-silencing mode.                                                                                                                                      |
| Kitty                 | Native light/dark theme files and portal events. USR1 also reloads changed assets without killing terminals or child shells. A fresh window uses the selected palette even before its first portal event. |
| Emacs                 | Existing toolkit-theme hooks select the exported palette pair. The curated config and synced style export are required.                                                                                   |
| GTK3                  | Named light/dark themes reload in open applications using normal GTK settings. Apps that force their own theme may differ.                                                                                |
| GTK4 and libadwaita   | New windows read selected CSS. Open applications can retain cached colors and need reopening. Appearance preference events alone do not reload their custom CSS.                                          |

Qt5/Qt6 apps using the configured Kvantum style read the selected theme on
startup. Reopen existing Qt apps after switching. Native qtct reloads can change
the renderer without changing the application palette, producing mixed colors;
this command does not request that partial reload or restart applications.
Application-specific themes can override this policy. Log out and back in after
deployment so new launches use the current Home Manager environment.

Chromium and Firefox pages that use `prefers-color-scheme` follow the desktop
preference live. This was tested with isolated Sim browser profiles, not the
user's extensions. Firefox reader view now uses its native Auto mode instead of
Stylix's fixed custom colors. Custom browser themes and extensions can still
override appearance; their preferences are not rewritten. TUIs and Hyprlock
remain static.

Flatpak theme injection remains outside this module. The old forced GTK theme
is no longer generated, but an override installed by an older generation can
persist. See the targeted cleanup below.

Quickshell uses one shared `Theme.qml` singleton. It watches atomic replacements
of the selection file and reads the selected immutable `palette.json`. Its text
roles keep Latte headings readable without using pale accent slots as foregrounds.
With runtime appearance disabled, the same singleton reads static Stylix colors.
This does not replace Waybar, Rofi, Mako, the lock screen, or the shell layout.

On Quickshell hosts, `mediactl` uses a themed volume, microphone, and brightness
OSD instead of the Avizo service. The existing vendor controls still choose the
playing sink, support boost/unmute, toggle all sinks or microphones, and change
backlight brightness. A private renderer adapter leaves those controls intact;
it does not replace global commands. Hosts without Quickshell retain Avizo.

The OSD follows the focused monitor, never takes keyboard focus, and dismisses
one second after the last repeated action. It remains below the session lock.
The gauge is capped at full scale and does not claim a numeric percentage when
boost exceeds 100%. If Quickshell is unavailable, the control still applies and
the command reports the missing feedback. `XF86AudioMicMute` now calls microphone
mute instead of night light. Real laptop backlight and microphone hardware still
need host acceptance.

Only the portal Settings backend is selected here. Existing screencast and file
chooser backend selection is left alone. Wallpaper selection remains independent.

## Existing Flatpak overrides

Inspect user-global overrides before changing them:

```sh
flatpak override --user --show
```

If `GTK_THEME=adw-gtk3` remains from the old Stylix setup, remove only that forced
environment value:

```sh
flatpak override --user --unset-env=GTK_THEME
```

This preserves other environment values and filesystem permissions. Do not use
`--reset` as a theme cleanup: it removes unrelated overrides too. An app-specific
override can take precedence; inspect it with `flatpak override --user --show APP_ID`
and use the same `--unset-env=GTK_THEME APP_ID` form if needed. System overrides
are separate. Reopen the app after cleanup. This removes a forced theme; it does
not guarantee that a sandboxed app will consume host CSS or retheme live.

No override cleanup runs automatically during activation.

## Desktop conveniences

- Super+F1 opens searchable Hyprland and keyd shortcut help. It does not execute
  the selected row. Live compositor descriptions include press, release, and
  hold actions; keyd rows include their keyboard, app, or layer context.
- Super+Alt+Shift+U toggles notification silencing. Waybar shows the current mode.
  Restore and dismiss shortcuts remain available.
- Waybar's cup still controls idle inhibition. It does not disable explicit
  locking or suspend. Blezz links to that existing control rather than adding
  another presentation-mode state.
- Super+Print reads English text from a screen region.
- Super+Shift+Print decodes a QR region into the current clipboard. The QR value
  is not put in the notification or logs. The sensitive clipboard hint prevents
  the configured Cliphist watcher from storing it. It remains available for
  normal paste until replaced; this is not an automatic clipboard wipe.
- Blezz includes the same appearance, capture, notification, wallpaper, LocalSend,
  and media-folder commands. Existing screenshot and recording workflows remain.

Other clipboard managers must honor the sensitive hint too. Do not claim privacy
with an untested clipboard manager. Canceling region selection leaves the current
clipboard alone and stops only the capture's own freeze process.

## Checks

After adding new source files to the Git index:

```sh
nix develop --command nix build '.#checks.x86_64-linux.desktop-theme' '.#checks.x86_64-linux.hyprland' '.#checks.x86_64-linux.quickshell' -L
```

The appearance check covers all four Hyprland hosts, rendered assets, GTK theme
ownership, concurrent selection, invalid state, missing assets, failed refreshes,
Lua colors, Qt palette roles and rendered Kvantum assets, Firefox reader policy,
capture cancellation, and the QR sensitive hint. Git flakes omit
untracked files. Never use raw `path:.` from this checkout; it includes ignored
Sim disks and private keys. Use a Git-filtered source snapshot for unstaged work.

For a running disposable Sim session:

```sh
python3 modules/home/desktop/default/options/desktop-theme/test-runtime.py /path/to/sim-user-command-wrapper
```

The wrapper must execute arbitrary command arguments as Sim's desktop user, with
its Wayland and D-Bus environment. The runner refuses another host. It checks
Kitty startup and live colors, portal events, Rofi colors, DND, reloads, shortcut
help, stable terminal PID, and unchanged system generation. It closes only its
own probe window and restores the original appearance and notification mode.

The Quickshell check exercises its actual FileView and IPC support without a
compositor, including atomic selection changes, rapid updates, and static mode.
For native popup tests, use `hyprland/quickshell/test-runtime.py` with its exported
config, Quickshell binary, assets, and Sim user-command wrapper. The runner uses
synthetic status data and never calls account actions or production status APIs.
It checks open/pinned state, unchanged data and process ID, and compositor reload.

For the media OSD, the same Sim wrapper can run:

```sh
python3 modules/home/desktop/hyprland/quickshell/test-media-runtime.py COMPILED_CONFIG QUICKSHELL_PACKAGE /path/to/sim-user-command-wrapper
```

This test owns a temporary shell, checks modes, palette changes, focus, focused
and explicit monitors, repeated dismissal, and an actual Wayland test lock.
It unlocks its own test lock before stopping. Run it only in disposable Sim.
Optional `MEDIA_OSD_SCREENSHOTS` selects a guest output directory;
`MEDIA_OSD_GRIM` selects the guest `grim` executable. Vendor mock and native IPC
checks run with the Quickshell Nix check. Virtual audio and desktop gamma can be
tested in Sim; real hardware brightness and mic behavior require host testing.

Also test GTK3 and Emacs live events, GTK4 reopen behavior, Home Manager activation,
and cold login. Capture checks need real screen content: decode a dummy QR, show
that a normal clipboard value enters Cliphist while the QR does not, run screen
OCR, and cancel a region selection. Mock checks alone cannot prove clipboard
privacy or app integration.
