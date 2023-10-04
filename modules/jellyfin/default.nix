# modules.jellyfin.enable = true;
{ config, lib, pkgs, ... }:


let

  cfg = config.modules.jellyfin;
  port = "8096"; 
  inherit (lib) mkIf mkOption types;

in {

  options.modules.jellyfin = {

    enable = lib.options.mkEnableOption "jellyfin"; 

    hostName = mkOption {
      type = types.str;
      default = "jellyfin.${config.networking.fqdn}";
      description = "FQDN for the Jellyfin instance";
    };

  };

  config = lib.mkIf cfg.enable {

    services.jellyfin = {
      enable = true;
      user = "jellyfin";
      group = "jellyfin";
      openFirewall = true;
    };

    users.groups.media.members = [ config.services.jellyfin.user ];

    # Enable reverse proxy
    modules.traefik.enable = true;

    services.traefik.dynamicConfigOptions.http = {
      routers.jellyfin = {
        entrypoints = "websecure";
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "jellyfin";
      };
      services.jellyfin.loadBalancer.servers = [{ url = "http://127.0.0.1:${port}"; }];

    };

  };

}
