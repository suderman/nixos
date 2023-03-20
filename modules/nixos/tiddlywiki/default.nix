# services.tiddlywiki.enable = true;
{ config, lib, pkgs, user, ... }:


let
  cfg = config.services.tiddlywiki;
  port = "3465"; 

in {

  config = lib.mkIf cfg.enable {

    # Add user to the tiddlywiki group
    users.users."${user}".extraGroups = [ "tiddlywiki" ]; 

    services.tiddlywiki.listenOptions = {
      port = lib.strings.toInt port;
      # credentials = "../credentials.csv";
      # readers="(authenticated)";
    };

    services.traefik.dynamicConfigOptions.http = with config.networking; {
      routers.tiddlywiki = {
        entrypoints = "websecure";
        rule = "Host(`wiki.${hostName}.${domain}`) || Host(`wiki.local.${domain}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "tiddlywiki";
      };
      services.tiddlywiki.loadBalancer.servers = [{ url = "http://127.0.0.1:${port}"; }];
    };

  };

}
