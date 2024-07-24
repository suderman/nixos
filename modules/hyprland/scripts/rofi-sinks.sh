#!/usr/bin/env bash
echo -en "\0prompt\x1f\n"

# Prep dirs/files
dir=$XDG_RUNTIME_DIR/sinks
mkdir -p $dir
echo "$(cat $XDG_CONFIG_HOME/rofi/extra.sinks)" > $dir/extra
cat $XDG_CONFIG_HOME/rofi/hidden.sinks > $dir/hidden


# Create a rofi-formatted option for a provided sink that appears nice
named_sink() {
  sink="${1-unknown}"

  # Lookup sink name in case it already exists
  name="$(pactl -f json list sinks | jq -r '
    .[] | select(.name == "'$sink'") |
    (.properties."device.description") as $device |
    (.ports | map(select(.availability != "not available") | .description) | join(" / ")) as $ports |
    "\($ports)\\t\($device)"
  ')"

  # Did we find a name?
  if [[ -z "$name" ]]; then

    # Try to get name from bluetoothctl (if paired)
    if [[ "$sink" =~ ^bluez.* ]]; then
      addr="$(echo $sink | tr _ : | awk -F. '{ print $2 }')"
      name="$(bluetoothctl devices | grep $addr | awk '{ $1=""; $2=""; print $0 }' | xargs)"
      [[ -z "$name" ]] && name="$addr"

    # All else fails, try to pretty-up this unknown sink name
    else
      name="$(echo "$sink" |\
        sed -r 's/^(.+)_output.//' |\
        sed 's/.*/\L&/; s/[a-z]*/\u&/g' |\
        tr _ ' ')"

    fi
  fi

  echo -en $name
}


# Attempt to connect a sink to bluetooth where applicable
connect_sink() {
  sink="${1-unknown}"

  # Only try to connect if sink is bluetooth
  if [[ "$sink" =~ ^bluez.* ]]; then

    # Get name from bluetoothctl (if paired)
    addr="$(echo $sink | tr _ : | awk -F. '{ print $2 }')"

    # If device is paired, attempt to connect (two times in case of timeout)
    if [[ ! -z "$(bluetoothctl devices | grep $addr)" ]]; then
      bluetoothctl unblock $addr >/dev/null 2>&1
      bluetoothctl connect $addr >/dev/null 2>&1 || bluetoothctl connect $addr >/dev/null 2>&1
    fi

  fi
}


# List all sinks if no arguments provided
if [ -z "${1-}" ]; then

  # detected sinks saved to file
  pactl -f json list sinks | jq -r '.[] |
    select(.ports[].availability != "not available") |
    (.properties."device.description") as $device |
    (.ports | map(select(.availability != "not available") | .description) | join(" / ")) as $ports |
    (if .name == "'$(pactl get-default-sink)'" then "audio-on" else "audio-ready" end) as $icon |
    (.name) as $sink |
    "\($ports)\\t\($device)\\0icon\\x1f\($icon)\\x1finfo\\x1f\($sink)"
    ' | uniq > $dir/detected

  # extra sinks added to copy of file
  cat $dir/detected > $dir/appended
  while read sink; do

    # ensure this extra sink wasn't already detected
    if [[ -z "$(grep $sink $dir/detected)" ]]; then

      # Add the sink to the list, formatted nice for rofi
      icon="audio-off"
      echo -n "$(named_sink $sink)\\0icon\\x1f${icon}\\x1finfo\\x1f${sink}" >> $dir/appended

    fi
  done < $dir/extra

  # output sinks, filtering any sinks to be hidden
  filter="$(sed -z s/.$// $dir/hidden | tr '\n' '|' )"

  # if there are no hidden sinks to filter, just output appended
  if [[ -z "$filter" ]]; then
    echo -en "$(cat $dir/appended)"

  # if there are, filter with grep
  else
    echo -en "$(grep -vE "${filter}" $dir/appended)"
  fi


# If there is an argument, change to the selected sink
else

  # get sink id from info
  sink="$(echo ${ROFI_INFO-unknown})"

  # connect sink if required (bluetooth)
  connect_sink "$sink"

  # update default sink
  pactl set-default-sink "$sink" 2>/dev/null && connected=yes || connected=no

  # check if successful
  if [[ "$connected" == "yes" ]]; then

    # move everything to this sink
    declare i
    pactl list short sink-inputs | awk '{print $1}' | while read -r i; do
      pactl move-sink-input "$i" "$sink"
    done

    # verify new default sink
    coproc hyprctl notify 1 3000 0 "  $(named_sink $sink)" 2>&1

  # failed to connect to sink
  else
    coproc hyprctl notify 3 3000 0 "  $(named_sink $sink)" 2>&1
  fi

fi
