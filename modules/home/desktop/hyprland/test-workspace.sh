#!/usr/bin/env bash
set -euo pipefail
helper="${1:?Workspace helper required}"

# Mock only IPC. Run the real helper against both workspace JSON formats.
hyprctl() {
  jq -c --arg query "$2" '.[$query]' <<<"$responses"
}
export -f hyprctl

expect() {
  local expected="$1" actual
  actual="$(bash "$helper" | jq -r .selector)"
  [[ $actual == "$expected" ]] || {
    echo "Expected $expected, got $actual" >&2
    exit 1
  }
}

export responses='{
  "monitors": [{"focused": true, "activeWorkspace": {"id": 1}, "specialWorkspace": {"id": 0, "name": ""}}],
  "workspaces": [
    {"id": 1, "name": "notes"},
    {"id": -1337, "name": "notes"},
    {"id": -99, "name": "special:scratch"}
  ]
}'
expect 1
responses="$(jq '.monitors[0].activeWorkspace.id = -1337' <<<"$responses")"
expect name:notes
responses="$(jq '.monitors[0].specialWorkspace = {id: -99, name: "special:scratch"}' <<<"$responses")"
expect special:scratch

responses='{
  "monitors": [{"focused": true, "activeWorkspace": {"address": "1"}, "specialWorkspace": {"address": "", "name": ""}}],
  "workspaces": [
    {"address": "1", "name": "notes"},
    {"address": "notes", "name": "notes"},
    {"address": "special:scratch", "name": "special:scratch"}
  ]
}'
expect 1
responses="$(jq '.monitors[0].activeWorkspace.address = "notes"' <<<"$responses")"
expect notes
responses="$(jq '.monitors[0].specialWorkspace = {address: "special:scratch", name: "special:scratch"}' <<<"$responses")"
expect special:scratch
printf 'workspace JSON selectors and special overlays: passed\n'
