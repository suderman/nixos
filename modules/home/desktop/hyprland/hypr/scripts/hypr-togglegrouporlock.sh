#!/usr/bin/env bash
# Optional f/b steps through the group before toggling.
case "${1:-}" in
"" | f | b) hyprctl eval "require('lib.util').toggle_group_or_lock('${1:-}')" ;;
*) exit 1 ;;
esac
