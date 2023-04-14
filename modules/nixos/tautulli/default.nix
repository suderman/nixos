# modules.tautulli.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.tautulli;
  inherit (lib) mkIf mkOption mkBefore types;
  inherit (builtins) toString;

in {

  options.modules.tautulli = {

    enable = lib.options.mkEnableOption "tautulli"; 

    hostName = mkOption {
      type = types.str;
      default = "tautulli.${config.networking.fqdn}";
      description = "FQDN for the Tautulli instance";
    };

    port = mkOption {
      description = "Port for Tautulli instance";
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

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Traefik proxy
    services.traefik.dynamicConfigOptions.http = {
      routers.tautulli = {
        entrypoints = "websecure";
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "tautulli";
      };
      services.tautulli.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString cfg.port}"; }];
    };


  };

}
