#!/usr/bin/env bash
flag="${1-rc}"
dir="${XDG_PICTURES_DIR-~/Pictures}/Screenshots"

# r: region
# s: screen
# c: clipboard
# f: file
# i: interactive
# p: pixel

# Region to clipboard
if [[ $flag == rc ]]; then
  grim -g "$(slurp -b '#000000b0' -c '#00000000')" - | wl-copy
  notify-send 'Copied to Clipboard' Screenshot

# Region to file
elif [[ $flag == rf ]]; then
  mkdir -p "$dir"
  filename="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
  grim -g "$(slurp -b '#000000b0' -c '#00000000')" "$filename"
  notify-send 'Screenshot Taken' "$filename"

# Region to interactive
elif [[ $flag == ri ]]; then
  grim -g "$(slurp -b '#000000b0' -c '#00000000')" - | tee >(wl-copy) | swappy -f -

# Screen to clipboard
elif [[ $flag == sc ]]; then
  grim - | wl-copy
  notify-send 'Copied to Clipboard' Screenshot

# Screen to file
elif [[ $flag == sf ]]; then
  mkdir -p "$dir"
  filename="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
  grim "$filename"
  notify-send 'Screenshot Taken' "$filename"

# Screen to interactive
elif [[ $flag == si ]]; then
  grim - | swappy -f -

# Colour to clipboard
elif [[ $flag == p ]]; then
  color="$(hyprpicker -a)"
  wl-copy "$color"
  notify-send 'Copied to Clipboard' "$color"
fi
