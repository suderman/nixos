#!/usr/bin/env bash

# First paramater is URL to add or loop for idleloop
param="${1:-none}"

# Optional mpd host and port paramaters
mpd_host="${2:-localhost}"
mpd_port="${3:-6600}"

# Directory used for lockfile and tag cache
dir="$HOME/.cache/mpc-url"
mkdir -p $dir

# Create mpc alias
alias mpc="mpc --host $mpd_host --port $mpd_port"

# Use yt-dlp to fetch url from src and append src at end as #fragment
get_url(){
  src="$1"
  url="$(yt-dlp -g --audio-format best "$src" | tail -n1)"
  echo "${url}#${src}"
}

# Fetch reversed songs in playlist with #http fragment, added to each line as src
get_songs(){
  mpc playlist -f "%position% %id% %file%" | awk '/#http/' | while read -r pos id url; do
    src="${url#*#}"
    echo "${pos} ${id} ${url} ${src}" 
  done | tac
}

# Get current http status code from url
get_status_code() {
  url="$1"
  wget -q --method=HEAD --server-response $url 2>&1 | awk '/HTTP\// {print $2}'
}

# Use yt-dlp to fetch title and channel separated by a newline
get_tags(){
  src="$1"

  # Save yt-dlp tags in cache on disk
  cache="$dir/$(echo "$src" | awk '{gsub(/[^a-zA-Z0-9._-]/, "_"); print}')"

  # Populate file if it doesn't exist output the contents
  if [[ ! -e "$cache" ]]; then
    yt-dlp -j $src | jq -r '.title, .uploader' > $cache
  fi
  cat $cache
}

# Transliteration of characters to their closest ASCII equivalents and tidy text
clean_tag(){
  echo "$1" | iconv -f utf8 -t ascii//TRANSLIT | awk '{
    gsub(/[^a-zA-Z0-9 ()&\/]/, " ");  # Replace special chars with space
    gsub(/ +/, " ");                  # Collapse multiple spaces
    sub(/^ +/, "");                   # Trim leading spaces
    sub(/ +$/, "");                   # Trim trailing spaces
    print $0
  }'
}

# Set an http song tag using netcat 
set_tag(){
  id="$1"
  name="$2"
  value="$3"
  (
    echo "cleartagid $id $name"
    echo "addtagid $id $name \"$value\""
    echo "close" 
  ) | nc $mpd_host $mpd_port
}

# First paramater is "loop", run the idleloop
if [[ $param == "loop" ]]; then

  # Set a lockfile so it only runs one at a time
  lockfile="$dir/mpc-url.lock"
  rm -f $lockfile

  # Watch for playlist changes
  echo "waiting for playlist changes"
  mpc idleloop playlist | while read change; do

    # Proceed if the lockfile isn't found
    if [[ ! -e "$lockfile" ]]; then

      # Create a lockfile 
      touch $lockfile
      (
        # Run script and remove lockfile when done
        $0 && sleep 1
        rm -f $lockfile

      ) & # run in background

    fi

  done
fi

# If url provided, add the song to the playlist
if [[ $param == http* ]]; then
  echo "add: $param"
  mpc add "$(get_url $param)"
fi

# Loop each http song playlist
get_songs | while read -r pos id url src; do

  echo "try: $src"
  
  # Check if the url has expired
  if [[ "$(get_status_code $url)" != "200" ]]; then

    echo "exp: $src"

    # Remove expired song from playlist by position
    mpc del $pos

    # Fetch new url from src and add to end of playlist
    mpc add "$(get_url $src)"

    # Move the newly added song from the bottom back to original position
    mpc move $(mpc playlist -f "%position%" | tail -n1) $pos

  fi

done

# Loop each http song playlist (again)
get_songs | while read -r pos id url src; do

  echo "tag: $src"

  tags="$(get_tags $src)"
  title="$(clean_tag "$(echo $tags | head -n1)")"
  artist="$(clean_tag "$(echo $tags | tail -n1)")"

  set_tag $id Title "$title" > /dev/null
  set_tag $id Artist "$artist" > /dev/null
  set_tag $id Album "$src" > /dev/null

done

echo "done"
