set -euo pipefail

usage() {
  printf 'Usage: desktop-theme [toggle|dark|light|get|apply|prepare]\n' >&2
  exit 64
}
[[ $# -le 1 ]] || usage
action=${1:-toggle}
case "$action" in toggle | dark | light | get | apply | prepare) ;; *) usage ;; esac

state=${XDG_STATE_HOME:-$HOME/.local/state}/desktop-theme
assets=@assets@
mode=@default@
if [[ -f "$state/mode" ]]; then
  read -r mode <"$state/mode" || [[ -n $mode ]]
  case "$mode" in dark | light) ;; *)
    printf 'Invalid desktop theme state\n' >&2
    exit 1
    ;;
  esac
fi
if [[ $action == get ]]; then
  printf '%s\n' "$mode"
  exit 0
fi

umask 077
mkdir -p "$state"
exec 9>"$state/lock"
flock 9
# Read again under the lock so concurrent toggles cannot lose a selection.
if [[ -f "$state/mode" ]]; then
  read -r mode <"$state/mode" || [[ -n $mode ]]
  case "$mode" in dark | light) ;; *)
    printf 'Invalid desktop theme state\n' >&2
    exit 1
    ;;
  esac
fi
case "$action" in
toggle) if [[ $mode == dark ]]; then mode=light; else mode=dark; fi ;;
dark | light) mode=$action ;;
esac
for file in palette.lua palette.json kitty.conf gtk.css waybar.css rofi.rasi mako.conf qt/qt5ct.conf qt/qt6ct.conf qt/palette.conf qt/kvantum.kvconfig qt/Kvantum/Desktop-$mode/Desktop-$mode.kvconfig qt/Kvantum/Desktop-$mode/Desktop-$mode.svg; do
  [[ -r "$assets/$mode/$file" ]] || {
    printf 'Missing desktop theme asset: %s\n' "$file" >&2
    exit 1
  }
done

# Only our selector changes. Config files and palettes remain declarative.
link="$state/current.new.$$"
selection="$state/mode.new.$$"
trap 'rm -f "$link" "$selection"' EXIT
ln -s "$assets/$mode" "$link"
mv -Tf "$link" "$state/current"
printf '%s\n' "$mode" >"$selection"
mv -f "$selection" "$state/mode"
[[ $action != prepare ]] || exit 0

failed=0
refresh() {
  local name=$1
  shift
  if ! "$@"; then
    printf 'Desktop theme selected, but %s refresh failed\n' "$name" >&2
    failed=1
  fi
}
if [[ -n ${WAYLAND_DISPLAY:-} && -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
  # Start the Settings backend before publishing an event. On a cold session,
  # Kitty discards its first portal reply rather than treating it as a change.
  refresh 'appearance portal' gdbus call --session \
    --dest org.freedesktop.portal.Desktop \
    --object-path /org/freedesktop/portal/desktop \
    --method org.freedesktop.portal.Settings.ReadOne \
    org.freedesktop.appearance color-scheme >/dev/null
fi
icons=@darkIcons@
[[ $mode != light ]] || icons=@lightIcons@
refresh 'appearance preference' dconf write /org/gnome/desktop/interface/color-scheme "'prefer-$mode'"
refresh 'GTK theme' dconf write /org/gnome/desktop/interface/gtk-theme "'desktop-$mode'"
refresh 'icon theme' dconf write /org/gnome/desktop/interface/icon-theme "'$icons'"

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  refresh Hyprland hyprctl eval 'require("lib.appearance").apply()'
fi
if pgrep -u "$UID" -x waybar >/dev/null; then
  refresh Waybar pkill -USR2 -u "$UID" -x waybar
fi
if pgrep -u "$UID" -x mako >/dev/null; then
  refresh Mako makoctl reload
fi
# Qt apps read the selected assets on startup. Do not request a partial style
# reload: pinned qtct/Kvantum can retain the old application palette.
if pgrep -u "$UID" -x kitty >/dev/null; then
  # Reload also picks up new palette assets when the preference did not change.
  refresh Kitty pkill -USR1 -u "$UID" -x kitty
fi
# Emacs follows the GTK preference event. No terminal restarts.
exit "$failed"
