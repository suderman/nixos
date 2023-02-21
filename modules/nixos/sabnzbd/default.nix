# services.sabnzbd.enable = true;
{ config, lib, pkgs, ... }:


let
  cfg = config.services.sabnzbd;
  port = "8008"; # default is 8080, must be updated in /var/lib/sabnzbd/sabnzbd.ini

in {

  config = lib.mkIf cfg.enable {

    services.sabnzbd.user = "sabnzbd";
    services.sabnzbd.group = "users";

    services.traefik.dynamicConfigOptions.http = with config.networking; {
      routers.sabnzbd = {
        entrypoints = "websecure";
        rule = "Host(`sab.${hostName}.${domain}`) || Host(`sab.local.${domain}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "sabnzbd";
      };
      services.sabnzbd.loadBalancer.servers = [{ url = "http://127.0.0.1:${port}"; }];
    };

  };

}
