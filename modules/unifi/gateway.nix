{ config, lib, pkgs, ... }:

let

  cfg = config.modules.unifi;
  ip = "192.168.1.1";
  hostName = "gateway.${config.networking.fqdn}";
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # Traefik proxy for gateway
    services.traefik.dynamicConfigOptions.http = {
      routers.unifi-gateway = {
        rule = "Host(`${hostName}`)";
        middlewares = "local@file";
        tls.certresolver = "resolver-dns";
        service = "unifi-gateway";
      };
      services.unifi-gateway.loadBalancer.servers = [{ url = "https://${ip}:443"; }];
    };

  };

}
