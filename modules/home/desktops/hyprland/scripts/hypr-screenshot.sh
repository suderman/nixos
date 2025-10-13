#!/usr/bin/env bash
action="${1-screen}"

# Screenshot
if [[ "$action" == "screen" ]]; then

  # Focused display
  output="$(hyprctl monitors | awk '/Monitor/{mon=$2} /focused: yes/{print mon}')"

  # Save location
  dir="${XDG_PICTURES_DIR-~/Pictures}/Screenshots"
  file="$dir/satty-$(date '+%Y%m%d-%H:%M:%S').png"

  # Send entire screen to satty for cropping and notation
  grim -o "$output" -t ppm -c - |
    satty --filename - \
      --fullscreen \
      --copy-command "wl-copy" \
      --output-filename "$file" |
    pngquant --quality=65-80 --speed 1 --strip input.png -o output.png

# Colour to clipboard
elif [[ "$action" == "color" ]]; then
  color="$(hyprpicker -a)"
  wl-copy "$color"
  notify-send 'Copied to Clipboard' "$color"
fi
