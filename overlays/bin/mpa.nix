{ lib, this, coreutils, gawk, gnused, inetutils, iconv, yt-dlp }: this.lib.mkShellScript {

  name = "mpa";
  inputs = [ coreutils gawk gnused inetutils iconv yt-dlp ];
  text = ''
    if [ $# -lt 1 ]; then
      echo "Usage: mpa URL [mpd_host] [mpd_port]"
      exit 1
    fi

    url="''${1:-}"
    mpd_host="''${2:-localhost}"
    mpd_port="''${3:-6600}"

    # Extract audio feed, send to mpd and and get back song_id
    song_id=$(
      {
        echo "addid $(yt-dlp -g "$url" | tail -n1)"
        sleep 1
      } | telnet "$mpd_host" "$mpd_port" 2>/dev/null | awk '/^Id:/ {print $NF}'
    )

    # Extract title and artist from title and uploader JSON
    yt-dlp -j $url > /tmp/yt.json

    title=$(cat /tmp/yt.json | jq -r '.title' | \
      iconv -f utf8 -t ascii//TRANSLIT | \
      sed 's/[^a-zA-Z0-9 ()&/]/ /g' | \
      tr -s ' ' | \
      sed 's/^ *//;s/ *$//')

    artist=$(cat /tmp/yt.json | jq -r '.uploader' | \
      iconv -f utf8 -t ascii//TRANSLIT | \
      sed 's/[^a-zA-Z0-9 ()&/]/ /g' | \
      tr -s ' ' | \
      sed 's/^ *//;s/ *$//')

    # Update tag info
    {
      echo "addtagid $song_id Artist \"$artist\""
      echo "addtagid $song_id Title \"$title\""
      echo "addtagid $song_id Album \"$url\""
      sleep 1
    } | telnet "$mpd_host" "$mpd_port" >/dev/null 2>&1
  '';

}

