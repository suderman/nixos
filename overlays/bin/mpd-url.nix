{ lib, this, fetchFromGitHub, coreutils, curl, gawk, jq, mpc-cli, netcat-gnu, yt-dlp }: this.lib.mkShellScript {

  # add URL streams to mpd using yt-dlp
  # https://github.com/suderman/mpd-url
  name = "mpd-url";
  inputs = [ coreutils curl gawk jq mpc-cli netcat-gnu yt-dlp ];
  text = let repo = fetchFromGitHub {
    owner = "suderman";
    repo = "mpd-url";
    rev = "3b9186d91046e6ad25ebddd21a40157f4ae49dce";
    sha256 = "sha256-cUz7iUBQCj9MtpwVKPcIW4nxg1lVByRfQ8RK3McvP2c=";
  }; in builtins.readFile "${repo}/mpd-url";

}
