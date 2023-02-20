# services.tandoor-recipes.enable = true;
{ config, lib, pkgs, ... }:

let
  cfg = config.services.tandoor-recipes;
  port = "8081";

in {

  config = lib.mkIf cfg.enable {

    services.tandoor-recipes.port = lib.strings.toInt port;

    services.traefik.dynamicConfigOptions.http = with config.networking; {
      routers.tandoor = {
        rule = "Host(`tandoor.${hostName}.${domain}`) || Host(`tandoor.local.${domain}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "tandoor";
      };
      services.tandoor.loadBalancer.servers = [{ url = "http://127.0.0.1:${port}"; }];
    };

  };

}
