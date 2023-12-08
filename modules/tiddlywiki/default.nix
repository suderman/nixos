# modules.tiddlywiki.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.tiddlywiki;
  inherit (lib) mkIf mkOption mkBefore types;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.tiddlywiki = {

    enable = lib.options.mkEnableOption "tiddlywiki"; 

    hostName = mkOption {
      type = types.str;
      default = "wiki.${config.networking.fqdn}";
      description = "FQDN for the Tiddlywiki instance";
    };

    port = mkOption {
      description = "Port for Tiddlywiki instance";
      default = 3456;
      type = types.port;
    };

  };

  config = mkIf cfg.enable {

    # Add admins to the tiddlywiki group
    users.users = extraGroups this.admins [ "tiddlywiki" ];

    services.tiddlywiki = {
      enable = true;
      listenOptions = {
        port = cfg.port;
        # credentials = "../credentials.csv";
        # readers="(authenticated)";
      };
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Traefik proxy
    services.traefik.dynamicConfigOptions.http = {
      routers.tiddlywiki = {
        entrypoints = "websecure";
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "tiddlywiki";
      };
      services.tiddlywiki.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString cfg.port}"; }];
    };

  };

}
