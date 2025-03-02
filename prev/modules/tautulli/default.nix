# services.tautulli.enable = true;
{ config, lib, pkgs, this, ... }: let

  cfg = config.services.tautulli;
  inherit (lib) mkIf mkOption mkBefore types;
  inherit (builtins) toString;

in {

  options.services.tautulli = {
    name = mkOption {
      type = types.str;
      default = "tautulli";
    };
  };

  config = mkIf cfg.enable {

    services.tautulli = {
      user = "plexpy";
      group = "nogroup";
      port = cfg.port;
      openFirewall = true;
    };

    services.traefik = {
      enable = true;
      proxy.${cfg.name} = "http://127.0.0.1:${toString cfg.port}"; # 8181
    };

  };

}
