{ lib, this, fetchFromGitHub, coreutils, curl, gawk, jq, mpc-cli, netcat-gnu, yt-dlp }: this.lib.mkShellScript {

  # add URL streams to mpd using yt-dlp
  # https://github.com/suderman/mpd-url
  name = "mpd-url";
  inputs = [ coreutils curl gawk jq mpc-cli netcat-gnu yt-dlp ];
  text = let repo = fetchFromGitHub {
    owner = "suderman";
    repo = "mpd-url";
    rev = "a17cd90974077db066c024fd9839d942a75098ff";
    sha256 = "sha256-WRRzIcVzYaI59tDlBXJ1yI2qD32+PKCEcf7NxwMDIU0=";
  }; in builtins.readFile "${repo}/mpd-url";

}
