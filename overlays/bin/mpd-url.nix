{ lib, this, fetchFromGitHub, coreutils, curl, gawk, jq, mpc-cli, netcat-gnu, yt-dlp }: this.lib.mkShellScript {

  # add URL streams to mpd using yt-dlp
  # https://github.com/suderman/mpd-url
  name = "mpd-url";
  inputs = [ coreutils curl gawk jq mpc-cli netcat-gnu yt-dlp ];
  text = let repo = fetchFromGitHub {
    owner = "suderman";
    repo = "mpd-url";
    rev = "d2484e52e06544ba9d7c28c98e374ac31aba482b";
    sha256 = "sha256-Dn5tZBkLNN5wikDgqueCY44L9AaCpo2x0y+vRQbsVH4=";
  }; in builtins.readFile "${repo}/mpd-url";

}
