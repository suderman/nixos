# services.tautulli.enable = true;
{ config, lib, pkgs, ... }:


let
  cfg = config.services.tautulli;
  port = "8181"; 

in {

  config = lib.mkIf cfg.enable {

    services.tautulli.user = "plexpy";
    services.tautulli.group = "nogroup";
    services.tautulli.port = lib.strings.toInt port;
    services.tautulli.openFirewall = true;

    services.traefik.dynamicConfigOptions.http = with config.networking; {
      routers.tautulli = {
        entrypoints = "websecure";
        rule = "Host(`tautulli.${hostName}.${domain}`) || Host(`tautulli.local.${domain}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "tautulli";
      };
      services.tautulli.loadBalancer.servers = [{ url = "http://127.0.0.1:${port}"; }];
    };

  };

}
