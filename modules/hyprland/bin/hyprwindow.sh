# Search all data directories for desktop entry file
function desktop_entry_path {
  class=$1; class_alt=$(echo $class | awk '{print tolower($1)}')
  for share in $(echo $XDG_DATA_DIRS | tr ":" " "); do 
    if [[ -e $share/applications/$class.desktop ]]; then
      echo $share/applications/$class.desktop
      return
    elif [[ -e $share/applications/$class_alt.desktop ]]; then
      echo $share/applications/$class_alt.desktop
      return
    fi
  done
}

# Extract icon and name from desktop entry file
function desktop_entry {
  path="$(desktop_entry_path $1)"
  if [[ -e $path ]]; then
    awk -F= "/^$2=/{print \$2; exit}" $path
  else
    echo "$1"
  fi
}

echo -en "\0prompt\x1f\n"
if [ -z "${1-}" ]; then

  # Fetch all windows sorted by focus
  hyprctl clients -j | jq -r 'sort_by(.focusHistoryID) | .[] | "\(.focusHistoryID) \(.class) \(.title)"' |\
  while read line; do
                
    # Split line into 3 fields
    id="$(echo $line | awk '{print $1}')"
    class="$(echo $line | awk '{print $2}')"
    title="$(echo $line | awk '{$1=""; $2=""; print}')"

    # Prepare options for row, extracted from desktop entry
    name="$(desktop_entry $class Name)"
    icon='\0icon\x1f'$(desktop_entry $class Icon)
    meta='\x1fmeta\x1f'${class}
    info='\x1finfo\x1f'${id}

    # Output the row
    echo -en "${name}\t${title}${icon}${meta}${info}\n"

  done

else

  # Focus selected window
  id=''${ROFI_INFO-0}
  addr="$(hyprctl clients -j | jq -r ".[] | select(.focusHistoryID==$id) | .address")"
  coproc hyprctl dispatch focuswindow address:$addr 2>&1

fi
