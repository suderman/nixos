#!/usr/bin/env bash
if [[ $# -lt 1 ]] || [[ "$1" == "add" ]]; then
  echo "Usage: mpc-url URL/COMMAND [mpd_host] [mpd_port]"
  echo " - URL: http/https add song via yt-dlp"
  echo " - COMMAND: flush/update/watch"
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
  file="$(echo "$src" | awk '{gsub(/[^a-zA-Z0-9._-]/, "_"); print}')"
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
fetch_artist() {
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
  mpc playlist -f "%position% %id% %file%" | awk '/https?:\/\//' | while read -r pos id url; do
    src="${url#*#}" # Look for src at end of url as #fragment
    [[ -z "$src" ]] && src="${url}" # fallback on url if src is empty
    echo "${pos} ${id} ${url} ${src}" 
  done | tac
}

# Get current http status code and content-type from url, return true if expired (or otherwise invalid) for streaming
is_invalid() {
  url="$1"
  wget -q --method=HEAD --server-response $url 2>&1 \
    | awk '{gsub(/^[[:space:]]+/,"")} tolower($0) ~ /^(content-type:|http\/)/ {print $2}' \
    > $dir/headers
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
  echo "$1" | iconv -f UTF-8 -t ascii//TRANSLIT 2>/dev/null | awk '{
    gsub(/[^a-zA-Z0-9 ()&\/]/, " ");  # Replace special chars with space
    gsub(/ +/, " ");                  # Collapse multiple spaces
    sub(/^ +/, "");                   # Trim leading spaces
    sub(/ +$/, "");                   # Trim trailing spaces
    print $0
  }'
}

# If url provided, add the song to the playlist
if [[ "$cmd" == "add" ]]; then
  echo "add: $src"
  mpc add "$(fetch_url $src)"

# Clear cache and reset playlist hash
elif [[ "$cmd" == "flush" ]]; then
  rm -f $dir/*
  echo "flush" > $dir/playlist

elif [[ "$cmd" == "update" ]]; then

  # Loop each http song playlist
  list_songs | while read -r pos id url src; do
    echo "src: $src"
    echo "url: $url"
    
    # Check if the url has expired
    if is_invalid "$url"; then
      echo "invalid: removed from playlist"

      # Fetch new url from src with forced flush
      url="$(fetch_url $src true)"
      echo "retry: $url"

      # Try again with new url
      if is_invalid "$url"; then
        echo "invalid: url failed"
        set_tag $id Title "invalid url" > /dev/null

      else
        echo "valid: url replaced in playlist"

        # Add new url to end of playlist
        mpc add "$url"

        # Remove expired song from playlist by position
        mpc del $pos

        # Move the newly added song from the bottom back to original position
        mpc move $(mpc playlist -f "%position%" | tail -n1) $pos
      fi

    fi
  done

  # Loop each http song playlist again
  list_songs | while read -r pos id url src; do

    # Set metadata for each track
    echo "tag: $src"
    (
      echo "cleartagid $id"
      echo "addtagid $id Title \"$(fetch_title $src)\""
      echo "addtagid $id Artist \"$(fetch_artist $src)\""
      echo "addtagid $id Album \"$src\""
      echo "close" 
    ) | nc $mpd_host $mpd_port > /dev/null

  done
  echo "done"

# First parameter is "watch", watch for playlist changes
elif [[ "$cmd" == "watch" ]]; then

  # Ensure existance of hashfile representing current playlist
  echo "flush" > $dir/playlist # ensure this gets run the first time

  # Watch for playlist changes
  echo "watching for playlist changes"
  while true; do
    mpc idle playlist | while read; do

      # Get hash of playlist and check for any changes
      hash="$(mpc playlist -f "%file%" | sort | sha256sum)"
      if [[ "$hash" != "$(cat $dir/playlist)" ]]; then

        # Update hash and run this script with "update" command
        echo "$hash" > $dir/playlist
        $0 update

      fi

    done
    sleep 1
  done

else
  echo "Unknown command"
fi
