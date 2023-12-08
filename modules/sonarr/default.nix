# modules.sonarr.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.sonarr;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;

in {

  options.modules.sonarr = {
    enable = options.mkEnableOption "sonarr"; 
    hostName = mkOption {
      type = types.str; 
      default = "sonarr.${config.networking.fqdn}";
    };
    port = mkOption {
      type = types.port;
      default = 8989; 
    };
    dataDir= mkOption {
      type = types.str; 
      default = "/var/lib/sonarr"; 
    };
  };

  config = mkIf cfg.enable {

    services.sonarr = {
      enable = true;
      user = "sonarr";
      group = "media";
      package = pkgs.sonarr;
      dataDir = cfg.dataDir;
    };
    users.groups.media.members = [ config.services.sonarr.user ];

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Traefik proxy
    services.traefik.dynamicConfigOptions.http = {
      routers.sonarr = {
        entrypoints = "websecure";
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "sonarr";
      };
      services.sonarr.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString cfg.port}"; }];
    };

  };

}
