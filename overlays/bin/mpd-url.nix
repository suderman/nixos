{ lib, this, fetchFromGitHub, coreutils, curl, gawk, jq, mpc-cli, netcat-gnu, yt-dlp }: this.lib.mkShellScript {

  # add URL streams to mpd using yt-dlp
  # https://github.com/suderman/mpd-url
  name = "mpd-url";
  inputs = [ coreutils curl gawk jq mpc-cli netcat-gnu yt-dlp ];
  text = let repo = fetchFromGitHub {
    owner = "suderman";
    repo = "mpd-url";
    rev = "cd8dab8385f09f4b114a9d995044936e30fc1188";
    sha256 = "sha256-YI/fMxp82lJnq5wH8pv5s1NOC2logOoW37psMsvW8BU=";
  }; in builtins.readFile "${repo}/mpd-url";

}
