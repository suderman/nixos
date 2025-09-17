{
  config,
  lib,
  flake,
  ...
}: let
  inherit (lib) mkIf;
  enable = flake.lib.anyUser config (user: user.programs.steam.enable);
in {
  config = mkIf enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
    };
  };
}
