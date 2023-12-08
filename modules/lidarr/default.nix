# modules.lidarr.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.lidarr;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;

in {

  options.modules.lidarr = {
    enable = options.mkEnableOption "lidarr"; 
    hostName = mkOption {
      type = types.str; 
      default = "lidarr.${config.networking.fqdn}";
    };
    port = mkOption {
      type = types.port;
      default = 8686; 
    };
    dataDir = mkOption {
      type = types.str; 
      default = "/var/lib/lidarr"; 
    };
  };

  config = mkIf cfg.enable {

    services.lidarr = {
      enable = true;
      user = "lidarr";
      group = "media";
      package = pkgs.lidarr;
      dataDir = cfg.dataDir;
    };
    users.groups.media.members = [ config.services.lidarr.user ];

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Traefik proxy
    services.traefik.dynamicConfigOptions.http = {
      routers.lidarr = {
        entrypoints = "websecure";
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "lidarr";
      };
      services.lidarr.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString cfg.port}"; }];
    };

  };

}
