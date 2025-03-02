#!/usr/bin/env bash
flag="${1-rc}"

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
  mkdir -p ~/Pictures/Screenshots
  filename=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
  grim -g "$(slurp -b '#000000b0' -c '#00000000')" $filename
  notify-send 'Screenshot Taken' $filename

# Region to interactive
elif [[ $flag == ri ]]; then
  grim -g "$(slurp -b '#000000b0' -c '#00000000')" - | tee >(wl-copy) | swappy -f -
  # grim -g "$(slurp -b '#000000b0' -c '#00000000')" - | swappy -f -

# Screen to clipboard
elif [[ $flag == sc ]]; then
  filename=~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png
  grim - | wl-copy
  notify-send 'Copied to Clipboard' Screenshot

# Screen to file
elif [[ $flag == sf ]]; then
  mkdir -p ~/Pictures/Screenshots
  filename=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
  grim $filename
  notify-send 'Screenshot Taken' $filename

# Screen to interactive
elif [[ $flag == si ]]; then
  grim - | swappy -f -

# Colour to clipboard
elif [[ $flag == p ]]; then
  color=$(hyprpicker -a)
  wl-copy $color
  notify-send 'Copied to Clipboard' $color
fi
