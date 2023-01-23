{ config, lib, pkgs, ... }:

with config.networking; 

let
  cfg = config.services.sabnzbd;
  sub = "sab";
  port = "8008"; # default is 8080, must be updated in /var/lib/sabnzbd/sabnzbd.ini

in {

  # services.sabnzbd.enable = true;
  services.sabnzbd.user = "sabnzbd";
  services.sabnzbd.group = "users";

  services.traefik.dynamicConfigOptions.http = lib.mkIf cfg.enable {
    routers.sabnzbd = {
      entrypoints = "websecure";
      rule = "Host(`${sub}.${hostName}.${domain}`) || Host(`${sub}.local.${domain} || Host(`${sub}.${domain}`)";
      service = "sabnzbd";
      tls.certresolver = "resolver-dns";
    };
    services.sabnzbd.loadBalancer.servers = [{ url = "http://127.0.0.1:${port}"; }];
  };

}
