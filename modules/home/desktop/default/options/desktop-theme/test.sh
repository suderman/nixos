set -euo pipefail
source_dir=$1
assets=$2
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export HOME="$work/home" XDG_STATE_HOME="$work/state"
mkdir -p "$HOME" "$work/bin"
sed -e "s|@assets@|$assets|g" -e 's|@default@|dark|g' \
  -e 's|@lightIcons@|Qogir-Light|g' -e 's|@darkIcons@|Qogir-Dark|g' \
  "$source_dir/switch.sh" >"$work/switch"
printf '#!/bin/sh\nexit 0\n' >"$work/bin/dconf"
printf '#!/bin/sh\nexit 1\n' >"$work/bin/pgrep"
chmod +x "$work/bin/"*
export PATH="$work/bin:$PATH"
unset HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS
run() { bash "$work/switch" "$@"; }
[[ $(run get) == dark ]]
[[ ! -e "$XDG_STATE_HOME/desktop-theme" ]]
run prepare
[[ $(readlink "$XDG_STATE_HOME/desktop-theme/current") == "$assets/dark" ]]
run light
[[ $(run get) == light ]]
run prepare
[[ $(run get) == light ]]
run toggle
[[ $(run get) == dark ]]
# Each toggle reads the selection while holding the lock.
for i in {1..20}; do run toggle & done
wait
[[ $(run get) == dark ]]
if run bogus; then exit 1; else [[ $? == 64 ]]; fi
printf '#!/bin/sh\nexit 1\n' >"$work/bin/dconf"
if run light; then exit 1; fi
[[ $(run get) == light ]]
# A refresh failure reports partial application, but keeps the user's choice.
printf 'bogus\n' >"$XDG_STATE_HOME/desktop-theme/mode"
if run prepare; then exit 1; fi
printf 'dark\n' >"$XDG_STATE_HOME/desktop-theme/mode"
mkdir "$work/incomplete"
sed "s|$assets|$work/incomplete|g" "$work/switch" >"$work/missing"
if bash "$work/missing" light; then exit 1; fi
[[ $(run get) == dark ]]
mkdir "$work/partial"
cp -rL "$assets/light" "$work/partial/light"
chmod -R u+w "$work/partial/light"
rm "$work/partial/light/qt/qt6ct.conf"
sed "s|$assets|$work/partial|g" "$work/switch" >"$work/missing-qt"
if bash "$work/missing-qt" light; then exit 1; fi
[[ $(run get) == dark ]]
[[ -z $(find "$XDG_STATE_HOME/desktop-theme" -name '*.new.*' -print) ]]
printf 'theme selection, activation, concurrency and failure handling: passed\n'
