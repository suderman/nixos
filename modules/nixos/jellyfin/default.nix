# services.jellyfin.enable = true;
{ config, lib, pkgs, ... }:


let
  cfg = config.services.jellyfin;
  port = "8096"; 

in {

  config = lib.mkIf cfg.enable {

    services.jellyfin.user = "jellyfin";
    services.jellyfin.group = "jellyfin";
    services.jellyfin.openFirewall = true;

    services.traefik.dynamicConfigOptions.http = with config.networking; {
      routers.jellyfin = {
        entrypoints = "websecure";
        rule = "Host(`jellyfin.${hostName}.${domain}`) || Host(`jellyfin.local.${domain}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "jellyfin";
      };
      services.jellyfin.loadBalancer.servers = [{ url = "http://127.0.0.1:${port}"; }];

    };

  };

}
