#!/usr/bin/env bash
dir="${1:-next}" # next/prev

# Prev workspace
if [[ "$dir" == "prev" ]]; then
  hyprctl dispatch 'hl.dsp.focus({ workspace = "e-1" })'

# Next workspace
else
  hyprctl dispatch 'hl.dsp.focus({ workspace = "e+1" })'
fi

# # This was an attempt to prevent workspace wrapping but it wasn't smooth enough
# lockfile="${XDG_RUNTIME_DIR:-/tmp}/hypr-ws-existing-step.lock"
#
# exec 9>"$lockfile"
# flock -n 9 || exit 0
#
# current="$(hyprctl activeworkspace -j | jq -r '.id')"
#
# mapfile -t existing < <(
#   hyprctl workspaces -j |
#     jq -r '.[].id | select(. >= 1 and . <= 9)' |
#     sort -n
# )
#
# ((${#existing[@]})) || exit 0
#
# target=""
#
# if [[ "$dir" == "next" ]]; then
#   for id in "${existing[@]}"; do
#     if ((id > current)); then
#       target="$id"
#       break
#     fi
#   done
# else
#   for ((i = ${#existing[@]} - 1; i >= 0; i--)); do
#     id="${existing[$i]}"
#     if ((id < current)); then
#       target="$id"
#       break
#     fi
#   done
# fi
#
# [[ -n "$target" ]] || exit 0
#
# hyprctl dispatch workspace "$target" >/dev/null
