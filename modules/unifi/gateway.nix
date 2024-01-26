{ config, lib, pkgs, ... }:

let

  cfg = config.modules.unifi;
  ip = "10.1.0.1";
  hostName = "rt.${config.networking.fqdn}";
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
