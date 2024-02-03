{ config, lib, ... }:

let

  cfg = config.modules.home-assistant;
  inherit (lib) mkIf;

in {

  config = mkIf (cfg.enable && cfg.isy != "") {

    # Enable reverse proxy
    modules.traefik.enable = true;
    modules.traefik.certificates = [ cfg.isyHostName ];

    services.traefik.dynamicConfigOptions.http = {
      middlewares.isy = {
        headers.customRequestHeaders.authorization = "Basic {{ env `ISY_BASIC_AUTH` }}";
      };
      routers.isy = {
        rule = "Host(`${cfg.isyHostName}`)";
        middlewares = [ "local@file" "isy@file" ];
        tls.certresolver = "resolver-dns";
        service = "isy";
      };
      services.isy.loadBalancer.servers = [{ url = "http://${cfg.isy}:80"; }];
    };

  };

}
