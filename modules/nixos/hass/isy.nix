{ config, lib, ... }:

let

  inherit (lib) mkIf mkBefore types strings;
  inherit (builtins) toString readFile;

  cfg = config.services.docker-hass;
  host = "isy.${config.networking.fqdn}";
  ip = "192.168.2.3";

in {

  config = mkIf cfg.enable {

    services.traefik.dynamicConfigOptions.http = {
      middlewares.isy = {
        headers.customRequestHeaders.authorization = "Basic {{ env `ISY_BASIC_AUTH` }}";
      };
      routers.isy = {
        rule = "Host(`${host}`)";
        middlewares = [ "local@file" "isy@file" ];
        tls.certresolver = "resolver-dns";
        service = "isy";
      };
      services.isy.loadBalancer.servers = [{ url = "http://${ip}:80"; }];
    };

  };

}
