# programs.steam.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.programs.steam;
  inherit (lib) mkIf;
in {
  config = mkIf cfg.enable {
    programs.steam = {
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
    };
  };
}
