# services.sabnzbd.enable = true;
{ config, lib, pkgs, user, ... }:

let

  cfg = config.services.sabnzbd;
  inherit (lib) mkIf mkOption types;
  inherit (builtins) toString;

in {

  options = {
    services.sabnzbd.host = mkOption {
      type = types.str;
      default = "sab.${config.networking.fqdn}";
      description = "Host for sabnzbd";
    };
    # default is 8080, must be updated in /var/lib/sabnzbd/sabnzbd.ini
    services.sabnzbd.port = mkOption {
      description = "sabnzbd port";
      default = 8008;
      type = types.port;
    };
  };

  config = mkIf cfg.enable {

    services.sabnzbd.user = "sabnzbd";
    services.sabnzbd.group = "media";
    users.groups.media.members = [ user cfg.user ];

    services.traefik.dynamicConfigOptions.http = {
      routers.sabnzbd = {
        entrypoints = "websecure";
        rule = "Host(`${cfg.host}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "sabnzbd";
      };
      services.sabnzbd.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString cfg.port}"; }];
    };

  };

}
