#!/usr/bin/env bash
set -euo pipefail

# Profiles come from the application preparation commands, not saved runtime state.
apply() {
  local profile=$1 mode output rule reply width height refresh attempt
  mode=$(jq -r .mode <<<"$profile")
  output=$(jq -r .output <<<"$profile")
  if [[ ! $mode =~ ^([0-9]+)x([0-9]+)@([0-9.]+)(Hz)?$ ]]; then
    echo "Unsupported Sunshine Laptop mode: $mode" >&2
    return 1
  fi
  width=${BASH_REMATCH[1]}
  height=${BASH_REMATCH[2]}
  refresh=${BASH_REMATCH[3]}

  # Do not choose the first output or change position, transform, or other flags.
  hyprctl -j monitors | jq -e --arg output "$output" \
    'any(.[]; .name == $output and .disabled == false)' >/dev/null || return 1
  rule=$(jq -r 'to_entries | map("\(.key)=\(.value | tojson)") | join(",")
    | "hl.monitor({\(.)})"' <<<"$profile")
  reply=$(hyprctl eval "$rule") || return 1
  if [[ $reply != "ok" ]]; then
    printf '%s\n' "$reply" >&2
    return 1
  fi

  # Mode changes are asynchronous; an "ok" reply can still mean a fallback mode.
  for ((attempt = 0; attempt < 20; attempt++)); do
    if hyprctl -j monitors | jq -e \
      --argjson profile "$profile" --argjson width "$width" \
      --argjson height "$height" --argjson refresh "$refresh" '
        any(.[]; .name == $profile.output and .width == $width and .height == $height
          and .refreshRate > ($refresh - 0.2) and .refreshRate < ($refresh + 0.2)
          and .scale > (($profile.scale | tonumber) - 0.01)
          and .scale < (($profile.scale | tonumber) + 0.01))
      ' >/dev/null; then
      return 0
    fi
    sleep 0.1
  done
  echo "Sunshine Laptop output did not reach $mode at scale $(jq -r .scale <<<"$profile")" >&2
  return 1
}

case "${1:-}:$#" in
start:3)
  normalProfile=$2
  laptopProfile=$3
  if ! apply "$laptopProfile"; then
    echo "Sunshine Laptop setup failed; restoring the normal output." >&2
    apply "$normalProfile" || printf "Restore failed; run sunshine-laptop reset %q in Kit's graphical session.\n" "$normalProfile" >&2
    exit 1
  fi
  ;;
reset:2)
  apply "$2"
  ;;
*)
  echo "Usage: sunshine-laptop start NORMAL_JSON LAPTOP_JSON | reset NORMAL_JSON" >&2
  exit 2
  ;;
esac
