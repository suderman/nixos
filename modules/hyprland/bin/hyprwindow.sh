# Cache found names/icons
CACHE="$XDG_RUNTIME_DIR/hyprwindow"
mkdir -p $CACHE

# Overrides for misnamed classes
# echo "org.gimp.GIMP" > $CACHE/gimp-2.99.class
echo "app.bluebubbles.BlueBubbles" > $CACHE/bluebubbles.class

# Init directories to search for desktop entries
if [[ ! -e "$CACHE/appdirs" ]]; then
  touch $CACHE/appdirs
  for share in $(echo $XDG_DATA_DIRS | tr ":" " "); do 
    [[ -e $share/applications ]] && echo $share/applications >> $CACHE/appdirs
  done
fi
APPDIRS="$(cat $CACHE/appdirs)"


# Clear display prompt (don't show "hyprwindow")
echo -en "\0prompt\x1f\n"

# List all open windows if no arguments provided
if [ -z "${1-}" ]; then

  # Look for all unique classes from running client windows
  for class in $(hyprctl clients -j | jq -r '.[] | if .class == "" then (.title | gsub("[^a-zA-Z0-9.]";".")) else .class end' | sort | uniq); do 
    env="${CACHE}/${class}.env" 
    name="$class" icon="$class" 
    override="${CACHE}/${class}.class"

    # Check if env variable has been set yet
    if [[ ! -e $env ]]; then

      # Override class for *.desktop if override exists
      desktop="${class}.desktop"
      [[ -e $override ]] && desktop="$(cat $override).desktop"

      # Search for a desktop entry by filename matching class
      entry=""
      for appdir in $APPDIRS; do 
        if [[ -e $appdir/$desktop ]]; then
          entry="${appdir}/${desktop}"
        elif [[ -e $appdir/${desktop,,} ]]; then
          entry="${appdir}/${desktop,,}"
          break
        fi
      done

      # If desktop entry found, extract attribute
      if [[ -e $entry ]]; then
        name="$(awk -F= "/^Name=/{print \$2; exit}" $entry)"
        icon="$(awk -F= "/^Icon=/{print \$2; exit}" $entry)"
      fi

      # Save env file to disk
      echo -e "export NAME_${class//[^a-zA-Z0-9_]/_}=${name}" >> $env
      echo -e "export ICON_${class//[^a-zA-Z0-9_]/_}=${icon}" >> $env

    fi
  done

  # All env files together
  cat $CACHE/*.env > $CACHE/env

  # Load env variables into memory
  echo -en "$(source $CACHE/env && \

  # Order windows by MRU, Name falls back on title if class is empty, Tab separates title, Icon from class name, Class searchable as meta, Order passed as rofi info                
  hyprctl clients -j | jq -r \
    'sort_by(.focusHistoryID) | .[] | (if .class == "" then .title else .class end | gsub("[^a-zA-Z0-9_]";"_")) as $c | "${NAME_\($c)}\\t\( .title | gsub("_/$";"") )\\0icon\\x1f${ICON_\($c)}\\x1fmeta\\x1f\(.class)\\x1finfo\\x1f\(.focusHistoryID)"' |\

  # Replace all variables with values
  envsubst)"

# If there is an argument, focus on the selected window
else

  # Focus selected window
  addr="$(hyprctl clients -j | jq -r ".[] | select(.focusHistoryID==${ROFI_INFO-0}) | .address")"
  coproc hyprctl dispatch focuswindow address:$addr 2>&1

fi
