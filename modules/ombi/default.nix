# modules.ombi.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.ombi;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;

in {

  options.modules.ombi = {
    enable = options.mkEnableOption "ombi"; 
    hostName = mkOption {
      type = types.str; 
      default = "ombi.${config.networking.fqdn}";
    };
    port = mkOption {
      type = types.port;
      default = 5099; 
    };
  };

  config = mkIf cfg.enable {

    services.ombi = {
      enable = true;
      user = "ombi";
      group = "media";
      port = cfg.port;
    };
    users.groups.media.members = [ config.services.ombi.user ];

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Traefik proxy
    services.traefik.dynamicConfigOptions.http = {
      routers.ombi = {
        entrypoints = "websecure";
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "ombi";
      };
      services.ombi.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString cfg.port}"; }];
    };

  };

}
