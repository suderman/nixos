{
  flake,
  pkgs,
  ...
}: let
  pin = flake.inputs.suderpkgs.pins.github.mpd-url;
in
  pkgs.stdenvNoCC.mkDerivation {
    pname = "mpd-url";
    version = builtins.substring 0 8 pin.rev;

    src = pkgs.fetchFromGitHub {
      inherit (pin) owner repo rev hash;
    };

    nativeBuildInputs = [pkgs.makeWrapper];

    installPhase = ''
      runHook preInstall

      install -Dm755 mpd-url $out/bin/mpd-url
      wrapProgram $out/bin/mpd-url \
        --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.curl pkgs.gawk pkgs.jq pkgs.mpc pkgs.netcat-gnu pkgs.yt-dlp]}

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Add URL streams to MPD using yt-dlp";
      platforms = platforms.linux;
    };
  }
