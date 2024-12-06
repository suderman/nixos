{ lib, this, fetchFromGitHub, coreutils, curl, gawk, jq, mpc-cli, netcat-gnu, yt-dlp }: this.lib.mkShellScript {

  # add URL streams to mpd using yt-dlp
  # https://github.com/suderman/mpd-url
  name = "mpd-url";
  inputs = [ coreutils curl gawk jq mpc-cli netcat-gnu yt-dlp ];
  text = let repo = fetchFromGitHub {
    owner = "suderman";
    repo = "mpd-url";
    rev = "fa245cc30b98e78f186b902835d72cefd0833279";
    sha256 = "sha256-MuhlY8OdC0pVB9Rj2oa0ODDT9nSa/37XHGnKKAOlB6Q=";
  }; in builtins.readFile "${repo}/mpd-url";

}
