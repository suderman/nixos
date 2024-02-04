# modules.tautulli.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.tautulli;
  inherit (lib) mkIf mkOption mkBefore types;
  inherit (builtins) toString;

in {

  options.modules.tautulli = {

    enable = lib.options.mkEnableOption "tautulli"; 

    name = mkOption {
      type = types.str;
      default = "tautulli";
    };

    port = mkOption {
      default = 8181;
      type = types.port;
    };

  };

  config = mkIf cfg.enable {

    services.tautulli = {
      enable = true;
      user = "plexpy";
      group = "nogroup";
      port = cfg.port;
      openFirewall = true;
    };

    modules.traefik = {
      enable = true;
      routers.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };

  };

}
