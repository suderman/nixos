{
  pkgs,
  perSystem,
  ...
}:
perSystem.self.mkScript {
  # add URL streams to mpd using yt-dlp
  # https://github.com/suderman/mpd-url
  name = "mpd-url";
  path = with pkgs; [coreutils curl gawk jq mpc-cli netcat-gnu yt-dlp];
  text = let
    repo = pkgs.fetchFromGitHub {
      owner = "suderman";
      repo = "mpd-url";
      rev = "09200dd2dbc3d51312cbf5881efc00678dce9a11";
      sha256 = "sha256-Wcl+wenrdkGOcjwFEmhCIVHIoZs97oMOrJzP1fbxtUE=";
    };
  in
    builtins.readFile "${repo}/mpd-url";
}
