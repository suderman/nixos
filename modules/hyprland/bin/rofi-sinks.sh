#!/usr/bin/env bash
echo -en "\0prompt\x1f\n"

# Prep dirs/files
dir=$XDG_RUNTIME_DIR/sinks
mkdir -p $dir
touch $dir/extra $dir/hidden


# Crete a rofi-formatted option for a provided sink that appears nice
extra_sink() {

  # Lookup sink name in case it already exists
  name="$(pactl -f json list sinks | jq -r '
    .[] | select(.name == "'$1'")
    .ports[].description +"\t"+ .properties."device.description"
  ')"

  # If not, and it's a bluetooth device, check if it's been paired to find the name that way
  if [[ -z "$name" ]] && [[ "$1" =~ ^bluez.* ]]; then

    # Get name from bluetoothctl (if paired)
    addr="$(echo $1 | tr _ : | awk -F. '{ print $2 }')"
    name="$(bluetoothctl devices | grep $addr | awk '{ $1=""; $2=""; print $0 }' | xargs)"
    [[ -z "$name" ]] && name="$addr"

  else
    name="$(echo "$1" \
      sed -r 's/^(.+)_output.//' |\
      sed 's/.*/\L&/; s/[a-z]*/\u&/g' |\
      tr _ ' ')"
  fi

  # Output option for rofi
  echo -n "${name}\\0icon\\x1fvolume-level-muted\\x1finfo\\x1f${1}"

}


# List all sinks if no arguments provided
if [ -z "${1-}" ]; then

  # detected sinks saved to file
  pactl -f json list sinks | jq -r '.[] |
    select(.ports[].availability == "available" or .ports[].availability == "availability unknown") |
    ( .ports[].description +"\t"+ .properties."device.description" ) as $title |
    ( if .state == "RUNNING" then "volume-level-high" else "volume-level-none" end ) as $icon |
    "\($title)\\0icon\\x1f\($icon)\\x1finfo\\x1f\(.name)"
    ' > $dir/detected

  # extra sinks added to copy of file
  cat $dir/detected > $dir/appended
  while read sink; do
    # ensure this extra sink wasn't already detected
    if [[ -z "$(grep $sink $dir/detected)" ]]; then 
      # Add the sink to the list, formatted nice for rofi
      extra_sink "$sink" >> $dir/appended
    fi
  done < $dir/extra

  # output sinks, filtering any sinks to be hidden
  filter="$(cat $dir/hidden | tr '\n' '|')"
  [[ -z "$filter" ]] && filter="show-all-sinks"
  echo -en "$(grep -vE "$filter" $dir/appended)"


# If there is an argument, change to the selected sink
else

  # get sink id from info
  id="$(echo ${ROFI_INFO-0})"

  # update default sink
  pactl set-default-sink "$id"

  # move everything to this sink
  declare i
  pactl list short sink-inputs | awk '{print $1}' | while read -r i; do
    pactl move-sink-input "$i" "$id"
  done

fi
