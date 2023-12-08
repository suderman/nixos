# modules.radarr.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.radarr;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;

in {

  options.modules.radarr = {
    enable = options.mkEnableOption "radarr"; 
    hostName = mkOption {
      type = types.str; 
      default = "radarr.${config.networking.fqdn}";
    };
    port = mkOption {
      type = types.port;
      default = 7878; 
    };
    dataDir = mkOption {
      type = types.str; 
      default = "/var/lib/radarr"; 
    };
  };

  config = mkIf cfg.enable {

    services.radarr = {
      enable = true;
      user = "radarr";
      group = "media";
      package = pkgs.radarr;
      dataDir = cfg.dataDir;
    };
    users.groups.media.members = [ config.services.radarr.user ];

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Traefik proxy
    services.traefik.dynamicConfigOptions.http = {
      routers.radarr = {
        entrypoints = "websecure";
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "radarr";
      };
      services.radarr.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString cfg.port}"; }];
    };

  };

}
