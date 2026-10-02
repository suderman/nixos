#!/usr/bin/env bash
set -euo pipefail
umask 077

state="${XDG_RUNTIME_DIR:?}/sunshine-phone-${HYPRLAND_INSTANCE_SIGNATURE:?}.json"
rule='"hl.monitor({output=\(.output | tojson),scale=\(.scale)})"'

case "${1:-}" in
start)
  # Keep the original scale if the same phone session is started again.
  if [[ ! -e $state ]]; then
    monitor=$(hyprctl -j monitors | jq -ce '
        .[0] | select(.name != null and .scale != null)
        | {output: .name, scale: .scale}
      ')
    printf '%s\n' "$monitor" >"$state"
  fi
  command=$(jq -r ".scale = 2.5 | $rule" "$state")
  ;;
reset)
  [[ -e $state ]] || exit 0
  command=$(jq -r "$rule" "$state")
  ;;
*)
  echo "Usage: sunshine-phone start|reset" >&2
  exit 2
  ;;
esac

# hyprctl can report an IPC error in its response without a failing exit status.
reply=$(hyprctl eval "$command")
if [[ $reply != "ok" ]]; then
  printf '%s\n' "$reply" >&2
  exit 1
fi

if [[ $1 == "reset" ]]; then
  rm "$state"
fi
