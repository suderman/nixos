{ lib, this, fetchFromGitHub, coreutils, curl, gawk, jq, mpc-cli, netcat-gnu, yt-dlp }: this.lib.mkShellScript {

  # add URL streams to mpd using yt-dlp
  # https://github.com/suderman/mpd-url
  name = "mpd-url";
  inputs = [ coreutils curl gawk jq mpc-cli netcat-gnu yt-dlp ];
  text = let repo = fetchFromGitHub {
    owner = "suderman";
    repo = "mpd-url";
    rev = "d4aa6d47f6f2f6911bbc6ad9dc031a188ba5f14f";
    sha256 = "sha256-k6gpD1XnowmpeU06wBhwpv2U6IcISwT4nlUXFgNpXMs=";
  }; in builtins.readFile "${repo}/mpd-url";

}
