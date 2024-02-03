{ config, lib, pkgs, ... }:

let

  cfg = config.modules.unifi;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # Enable reverse proxy
    modules.traefik.enable = true;
    # modules.traefik.certificates = [ cfg.gatewayHostName ];

    # Traefik proxy for gateway
    services.traefik.dynamicConfigOptions.http = {
      routers.unifi-gateway = {
        rule = "Host(`${cfg.gatewayHostName}`)";
        middlewares = "local@file";
        tls.certresolver = "resolver-dns";
        service = "unifi-gateway";
      };
      services.unifi-gateway.loadBalancer.servers = [{ url = "https://${cfg.gateway}:443"; }];
    };

  };

}
