{ config, lib, pkgs, ... }:

with config.networking; 

let
  cfg = config.services.tandoor-recipes;
  sub = "tandoor";
  port = "8081";

in {

  # services.tandoor-recipes.enable = true;
  services.tandoor-recipes.port = lib.strings.toInt port;

  services.traefik.dynamicConfigOptions.http = lib.mkIf cfg.enable {
    routers.tandoor = {
      entrypoints = "websecure";
      rule = "Host(`${sub}.${hostName}.${domain}`) || Host(`${sub}.local.${domain}`)";
      service = "tandoor";
      tls.certresolver = "resolver-dns";
    };
    services.tandoor.loadBalancer.servers = [{ url = "http://127.0.0.1:${port}"; }];
  };

}