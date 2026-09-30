#!/usr/bin/env bash
set -euo pipefail

# Special workspaces are overlays, not the monitor's activeWorkspace.
workspace="$(hyprctl -j monitors | jq -c '
  .[] | select(.focused) |
  if .specialWorkspace.name != "" then .specialWorkspace else .activeWorkspace end
')"
hyprctl -j workspaces | jq --argjson workspace "$workspace" '
  .[] | select((.address // .id) == ($workspace.address // $workspace.id)) |
  . + {selector: (.address // (
    if (.name | startswith("special:")) then .name
    elif .id > 0 then (.id | tostring)
    else "name:" + .name end
  ))}
'
