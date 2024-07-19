#!/usr/bin/env bash
echo -en "\0prompt\x1f\n"

# List all sinks if no arguments provided
if [ -z "${1-}" ]; then

  # Directory of blessed sinks and names
  dir="$XDG_RUNTIME_DIR/sinks"

  # Loop through all active sinks
  for line in $(pactl list short sinks | awk '{print $1 "|" $2}'); do

    # Extract id and check in directory
    sink="$(echo $line | awk -F'|' '{print $2}')"
    if [[ -e $dir/$sink ]]; then 

      # Extract number and name 
      id="$(echo $line | awk -F'|' '{print $1}')"
      name="$(cat $dir/$sink)"

      # Echo this line for rofi
      echo -en "$name\0icon\x1fspeaker\x1finfo\x1f${id}\n"

    fi

  done

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
