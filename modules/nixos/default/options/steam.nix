{
  config,
  lib,
  ...
}: let
  inherit (builtins) attrNames any;
  inherit (lib) mkIf;
  # If any home-manager steam is enabled for any user, set this to true
  users = config.home-manager.users or {};
  enable = any (user: users.${user}.programs.steam.enable or false) (attrNames users);
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
