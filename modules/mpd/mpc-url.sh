#!/usr/bin/env bash
if [[ $# -lt 1 ]] || [[ "$1" == "add" ]]; then
  echo "Usage: mpc-url URL/COMMAND [mpd_host] [mpd_port]"
  echo " - URL: http/https add song via yt-dlp"
  echo " - COMMAND: update/watch"
  exit 1
fi

# If first paramater is URL, use it as src and set cmd to "add"
cmd="${1:-none}"
if [[ $cmd == http* ]]; then
  src="$cmd"
  cmd="add"
fi

# Optional mpd host and port paramaters
mpd_host="${2:-localhost}"
mpd_port="${3:-6600}"

# Directory used for tag cache and playlist hash
dir="$HOME/.cache/mpc-url"
mkdir -p $dir

# Create mpc alias
alias mpc="mpc --host $mpd_host --port $mpd_port"

# Use yt-dlp to fetch title, artist and url from src
# Save result and return cached value if available
fetch() {
  src="$1"
  flush="${2-false}" # flush cache for this src, always fetch fresh
  file="f$(echo "$src" | sha256sum | awk '{print $1}')"
  if [[ ! -e $dir/$file || "$flush" == "true" ]]; then
    # fetch metadata on first two lines
    yt-dlp -j $src | jq -r '.title, .uploader' > $dir/$file
    # fetch url on last line and append src to end as #fragment
    echo "$(yt-dlp -g --audio-format=best $src | tail -n1)#${src}" >> $dir/$file
  fi
  cat $dir/$file
}

# First line of cache
fetch_title() {
  src="$1"
  flush="${2-false}"
  clean_tag "$(fetch "$src" "$flush" | head -n1)"
}

# Second line of cache
fetch_uploader() {
  src="$1"
  flush="${2-false}"
  clean_tag "$(fetch "$src" "$flush" | head -n2 | tail -n1)"
}

# Last line of cache
fetch_url() {
  src="$1"
  flush="${2-false}"
  fetch "$src" "$flush" | tail -n1
}

# Fetch reversed songs in playlist with #http fragment, added to each line as src
list_songs() {
  while read -r pos id url; do
    src="${url#*#}" # Look for src at end of URL as #fragment
    [[ -z "$src" ]] && src="${url}" # Fallback on URL if src is empty
    echo "${pos} ${id} ${url} ${src}"
  done < <(mpc playlist -f "%position% %id% %file%" | awk '/https?:\/\//') | tac
}

# Get current http status code and content-type from url, return true if expired (or otherwise invalid) for streaming
is_invalid() {
  url="$1"
  curl -sILw "__ %{http_code}\n__ %{content_type}\n" "$url" | awk 'tolower($0) ~ /^__/ {print $2}' > $dir/headers
  status_code="$(cat $dir/headers | head -n1)"
  content_type="$(cat $dir/headers | tail -n1)"
  [[ -z "$content_type" ]] && content_type="text" # default to text if blank
  if [[ "$status_code" == "200" && ! "$content_type" =~ ^text ]]; then
    return 1 # false, it did not expire
  else
    return 0 # true, is is expired
  fi
}

# Transliteration of characters to their closest ASCII equivalents and tidy text
clean_tag() {
  echo "$1" | awk '{
    gsub(/[^a-zA-Z0-9 ()&\/]/, " ");  # Replace special chars with space
    gsub(/ +/, " ");                  # Collapse multiple spaces
    sub(/^ +/, "");                   # Trim leading spaces
    sub(/ +$/, "");                   # Trim trailing spaces
    print $0
  }'
}

# Set metadata for song
set_tag() {
  id="$1"
  src="${2-invalid}"
  title="invalid"
  uploader="invalid"
  if [[ "$src" != "invalid" ]]; then
    title="$(fetch_title $src)"
    uploader="$(fetch_uploader $src)"
  fi
  (
    echo "cleartagid $id"
    echo "addtagid $id Title \"$title\""
    echo "addtagid $id Album \"$uploader\""
    echo "addtagid $id Artist \"$src\""
    echo "close" 
  ) | nc $mpd_host $mpd_port > /dev/null
}

# Update the playlist, replacing any expired URLs and tagging tracks
update() {
  flush="${1-false}"

  # Only allow one instance of this function to run at a time
  if [[ -e "$dir/lock" ]]; then
    echo "locked"
    return
  fi

  # Ensure online before proceeding
  if ! nc -zw1 youtube.com 443; then
    echo "offline"
    return
  fi

  # Empty cache if flush set
  if [[ "$flush" == "flush" ]]; then
    rm -f $dir/f*
    echo "flush" > $dir/playlist
  fi

  # Create lockfile
  touch $dir/lock

  # Loop each http song playlist
  while read -r pos id url src; do
    echo "url: $url"
    
    # Check if the url has expired
    if is_invalid "$url"; then

      # Fetch new url from src with forced flush
      prev_url="$url"
      url="$(fetch_url $src true)"

      if [[ "$url" == "$prev_url" ]]; then
        echo "-> url fail"
        set_tag $id invalid

      else
        echo "-> url fail, retry: $url"

        # Try again with new url
        if is_invalid "$url"; then
          echo "-> url retry fail"
          set_tag $id invalid

        else
          echo "-> url retry pass"

          # Add new url to end of playlist
          mpc add "$url"

          # Remove expired song from playlist by position
          mpc del $pos

          # Move the newly added song from the bottom back to original position
          mpc move $(mpc playlist -f "%position%" | tail -n1) $pos
        fi
      fi

    else
      echo "-> url pass"
    fi

  done < <(list_songs)

  # Loop each http song playlist again
  while read -r pos id url src; do

    # Set metadata for each track
    echo "tag: $id -> $src"
    set_tag $id $src

  done < <(list_songs)

  # Remove lockfile when done
  rm -f $dir/lock
  echo "done"

}

# If url provided, add the song to the playlist
if [[ "$cmd" == "add" ]]; then
  echo "add: $src"
  mpc add "$(fetch_url $src)"

# Manually run update, with flushed cache and reset playlist hash
elif [[ "$cmd" == "update" ]]; then
  update flush

# First parameter is "watch", watch for playlist changes
elif [[ "$cmd" == "watch" ]]; then

  # Ensure no lockfile
  rm -f $dir/lock

  # Run update flushed
  update flush

  # Watch for playlist changes
  echo "watching for playlist changes"
  while true; do
    while read; do

      # Get hash of playlist and check for any changes
      hash="$(mpc playlist -f "%file%" | sort | sha256sum)"
      if [[ "$hash" != "$(cat $dir/playlist)" ]]; then

        # Update hash and run this script with "update" command
        echo "$hash" > $dir/playlist
        update

      fi

    done < <(mpc idle playlist)
    sleep 1
  done

else
  echo "Unknown command"
fi
