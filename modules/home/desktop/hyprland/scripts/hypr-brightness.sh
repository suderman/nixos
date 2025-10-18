#!/usr/bin/env bash
# smart-brightness: adjusts brightness either via hardware (lightctl)
# or via gamma (hyprsunset) depending on what's available.

set -euo pipefail

cmd="${1:-}"
[[ "$cmd" == "up" || "$cmd" == "down" ]] || {
  echo "Usage: $(basename "$0") up|down"
  exit 1
}

# Detect hardware backlight (using brightnessctl or lightctl)
has_hw_backlight() {
  brightnessctl --list 2>/dev/null | grep -q "backlight"
}

if has_hw_backlight; then
  # Hardware brightness path
  if [[ "$cmd" == "up" ]]; then
    lightctl up
  else
    lightctl down
  fi
else
  # Fallback to Hyprsunset gamma control
  # (read current gamma, adjust by ±10)
  delta=$([[ "$cmd" == "up" ]] && echo +10 || echo -10)
  hyprctl hyprsunset gamma "$delta"
fi
